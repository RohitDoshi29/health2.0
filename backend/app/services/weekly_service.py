"""Service for generating the Weekly Nutrition & Hydration Report."""

import uuid
from datetime import UTC, datetime, time, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.goal import Goal
from app.models.meal import Meal
from app.models.water_log import WaterLog
from app.models.weight_log import WeightLog
from app.schemas.weekly import (
    DailyAveragesRead,
    DailyBarPoint,
    DaySummaryRead,
    NutrientHitsRead,
    PriorWeekComparisonRead,
    WeeklyReportResponse,
    WeightChangeRead,
)
from app.services.streak_service import calculate_daily_score


class WeeklyService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_weekly_report(
        self, user_id: uuid.UUID, week_offset: int = 0, tz_offset: int = 0
    ) -> WeeklyReportResponse:
        client_now = datetime.now(UTC) + timedelta(minutes=tz_offset)
        today = client_now.date()

        # Week starts Monday (ISO weekday 0)
        monday = today - timedelta(days=today.weekday()) + timedelta(weeks=week_offset)
        sunday = monday + timedelta(days=6)

        # UTC ranges for current week window
        start_dt = datetime.combine(monday, time.min).replace(tzinfo=UTC) - timedelta(
            minutes=tz_offset
        )
        end_dt = datetime.combine(sunday, time.max).replace(tzinfo=UTC) - timedelta(
            minutes=tz_offset
        )

        # Prior week window
        prior_monday = monday - timedelta(days=7)
        prior_sunday = monday - timedelta(days=1)
        prior_start_dt = datetime.combine(prior_monday, time.min).replace(tzinfo=UTC) - timedelta(
            minutes=tz_offset
        )
        prior_end_dt = datetime.combine(prior_sunday, time.max).replace(tzinfo=UTC) - timedelta(
            minutes=tz_offset
        )

        # Get user goal targets
        goal_result = await self.db.execute(select(Goal).where(Goal.user_id == user_id))
        goal = goal_result.scalar_one_or_none()
        cal_target = goal.calorie_target if goal else 2000.0
        prot_target = goal.protein_target if goal else 120.0
        carbs_target = goal.carbohydrates_target if goal else 250.0
        fat_target = goal.fat_target if goal else 65.0
        fib_target = goal.fiber_target if goal else 30.0
        wat_target = goal.water_target_ml if goal else 2500.0

        # Query meals for current week
        meal_res = await self.db.execute(
            select(Meal).where(
                Meal.user_id == user_id,
                Meal.created_at >= start_dt,
                Meal.created_at <= end_dt,
            )
        )
        meals = list(meal_res.scalars().all())

        # Query water logs for current week
        water_res = await self.db.execute(
            select(WaterLog).where(
                WaterLog.user_id == user_id,
                WaterLog.logged_at >= start_dt,
                WaterLog.logged_at <= end_dt,
            )
        )
        water_logs = list(water_res.scalars().all())

        # Query weight logs for current week
        weight_res = await self.db.execute(
            select(WeightLog)
            .where(
                WeightLog.user_id == user_id,
                WeightLog.logged_at >= start_dt,
                WeightLog.logged_at <= end_dt,
            )
            .order_by(WeightLog.logged_at.asc())
        )
        weight_logs = list(weight_res.scalars().all())

        # Group data per day of week (7 days: Monday to Sunday)
        days_map: dict[str, dict[str, float]] = {}
        for i in range(7):
            day_d = monday + timedelta(days=i)
            days_map[day_d.isoformat()] = {
                "calories": 0.0,
                "protein": 0.0,
                "carbohydrates": 0.0,
                "fat": 0.0,
                "fiber": 0.0,
                "water": 0.0,
            }

        for m in meals:
            m_date = (m.created_at + timedelta(minutes=tz_offset)).date().isoformat()
            if m_date in days_map:
                days_map[m_date]["calories"] += m.total_calories
                days_map[m_date]["protein"] += m.total_protein
                days_map[m_date]["carbohydrates"] += m.total_carbohydrates
                days_map[m_date]["fat"] += m.total_fat
                days_map[m_date]["fiber"] += m.total_fiber

        for w in water_logs:
            w_date = (w.logged_at + timedelta(minutes=tz_offset)).date().isoformat()
            if w_date in days_map:
                days_map[w_date]["water"] += w.amount_ml

        # Process each day
        total_calories = 0.0
        total_protein = 0.0
        total_carbs = 0.0
        total_fat = 0.0
        total_fiber = 0.0
        total_water = 0.0

        hits_cal = 0
        hits_prot = 0
        hits_carbs = 0
        hits_fat = 0
        hits_fib = 0
        hits_wat = 0

        daily_points: list[DailyBarPoint] = []
        day_summaries: list[DaySummaryRead] = []

        for i in range(7):
            d = monday + timedelta(days=i)
            d_str = d.isoformat()
            vals = days_map[d_str]
            day_name = d.strftime("%A")

            cal = vals["calories"]
            prot = vals["protein"]
            carbs = vals["carbohydrates"]
            fat = vals["fat"]
            fib = vals["fiber"]
            wat = vals["water"]

            total_calories += cal
            total_protein += prot
            total_carbs += carbs
            total_fat += fat
            total_fiber += fib
            total_water += wat

            score, _ = calculate_daily_score(
                calories=cal,
                protein=prot,
                fiber=fib,
                water_ml=wat,
                calorie_target=cal_target,
                protein_target=prot_target,
                fiber_target=fib_target,
                water_target_ml=wat_target,
            )

            # Target hit rules
            cal_hit = (round(0.90 * cal_target, 2) <= cal <= round(1.10 * cal_target, 2)) and (
                cal > 0
            )
            prot_hit = (prot >= round(0.90 * prot_target, 2)) and (prot > 0)
            carbs_hit = (carbs >= round(0.80 * carbs_target, 2)) and (carbs > 0)
            fat_hit = (fat >= round(0.80 * fat_target, 2)) and (fat > 0)
            fib_hit = (fib >= round(0.80 * fib_target, 2)) and (fib > 0)
            wat_hit = (wat >= round(1.00 * wat_target, 2)) and (wat > 0)

            if cal_hit:
                hits_cal += 1
            if prot_hit:
                hits_prot += 1
            if carbs_hit:
                hits_carbs += 1
            if fat_hit:
                hits_fat += 1
            if fib_hit:
                hits_fib += 1
            if wat_hit:
                hits_wat += 1

            day_summaries.append(
                DaySummaryRead(
                    date=d_str,
                    day_name=day_name,
                    score=score,
                    calories=round(cal, 1),
                )
            )

            daily_points.append(
                DailyBarPoint(
                    date=d_str,
                    day_name=day_name[:3],
                    calories=round(cal, 1),
                    calorie_target=round(cal_target, 1),
                    score=score,
                    target_hit=cal_hit,
                )
            )

        # Daily averages across the 7 days of the week
        daily_averages = DailyAveragesRead(
            calories=round(total_calories / 7.0, 1),
            protein=round(total_protein / 7.0, 1),
            carbohydrates=round(total_carbs / 7.0, 1),
            fat=round(total_fat / 7.0, 1),
            fiber=round(total_fiber / 7.0, 1),
            water_ml=round(total_water / 7.0, 1),
        )

        # Best day and worst day
        best_day = max(day_summaries, key=lambda s: s.score)
        worst_day = min(day_summaries, key=lambda s: s.score)

        # Weight change in this window (first to last)
        weight_change: WeightChangeRead | None = None
        if weight_logs:
            start_wt = weight_logs[0].weight_kg
            end_wt = weight_logs[-1].weight_kg
            weight_change = WeightChangeRead(
                start_weight_kg=round(start_wt, 1),
                end_weight_kg=round(end_wt, 1),
                change_kg=round(end_wt - start_wt, 2),
            )

        # Prior week comparison
        prior_meal_res = await self.db.execute(
            select(Meal).where(
                Meal.user_id == user_id,
                Meal.created_at >= prior_start_dt,
                Meal.created_at <= prior_end_dt,
            )
        )
        prior_meals = list(prior_meal_res.scalars().all())
        prior_total_cals = sum(m.total_calories for m in prior_meals)
        prior_total_prot = sum(m.total_protein for m in prior_meals)

        prior_avg_cals = round(prior_total_cals / 7.0, 1)
        prior_avg_prot = round(prior_total_prot / 7.0, 1)

        # Calculate percentage changes (safe division by zero)
        if prior_avg_cals > 0:
            cal_pct_change = round(
                ((daily_averages.calories - prior_avg_cals) / prior_avg_cals) * 100.0, 1
            )
        else:
            cal_pct_change = None

        if prior_avg_prot > 0:
            prot_pct_change = round(
                ((daily_averages.protein - prior_avg_prot) / prior_avg_prot) * 100.0, 1
            )
        else:
            prot_pct_change = None

        prior_comparison = PriorWeekComparisonRead(
            prior_average_calories=prior_avg_cals,
            prior_average_protein=prior_avg_prot,
            calories_pct_change=cal_pct_change,
            protein_pct_change=prot_pct_change,
        )

        nutrient_hits = NutrientHitsRead(
            calories=hits_cal,
            protein=hits_prot,
            carbohydrates=hits_carbs,
            fat=hits_fat,
            fiber=hits_fib,
            water=hits_wat,
        )

        return WeeklyReportResponse(
            week_offset=week_offset,
            start_date=monday.isoformat(),
            end_date=sunday.isoformat(),
            daily_averages=daily_averages,
            best_day=best_day,
            worst_day=worst_day,
            nutrient_hits=nutrient_hits,
            weight_change=weight_change,
            prior_week_comparison=prior_comparison,
            daily_points=daily_points,
        )
