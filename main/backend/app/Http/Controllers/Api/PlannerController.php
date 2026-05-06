<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpsertPlannerRequest;
use App\Models\Planner;
use App\Services\StatsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class PlannerController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Planner::class);

        $filters = $request->validate([
            'from'     => ['sometimes', 'date_format:Y-m-d'],
            'to'       => ['sometimes', 'date_format:Y-m-d'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = Planner::query()->where('user_id', $request->user()->id);

        if (isset($filters['from'])) {
            $query->where('date', '>=', $filters['from']);
        }
        if (isset($filters['to'])) {
            $query->where('date', '<=', $filters['to']);
        }

        $perPage = $filters['per_page'] ?? 31;

        return response()->json(
            $query->orderByDesc('date')->paginate($perPage)
        );
    }

    public function show(Request $request, string $date): JsonResponse
    {
        $planner = Planner::where('user_id', $request->user()->id)
            ->where('date', $date)
            ->firstOrFail();

        $this->authorize('view', $planner);

        return response()->json($planner);
    }

    public function upsert(UpsertPlannerRequest $request, string $date, StatsService $stats): JsonResponse
    {
        $planner = Planner::updateOrCreate(
            ['user_id' => $request->user()->id, 'date' => $date],
            $request->validated(),
        );

        try {
            $stats->recompute($request->user());
        } catch (\Throwable $e) {
            report($e);
        }

        return response()->json(
            $planner,
            $planner->wasRecentlyCreated ? Response::HTTP_CREATED : Response::HTTP_OK,
        );
    }

    public function destroy(Request $request, string $date, StatsService $stats): Response
    {
        $planner = Planner::where('user_id', $request->user()->id)
            ->where('date', $date)
            ->firstOrFail();

        $this->authorize('delete', $planner);

        $planner->delete();

        try {
            $stats->recompute($request->user());
        } catch (\Throwable $e) {
            report($e);
        }

        return response()->noContent();
    }
}
