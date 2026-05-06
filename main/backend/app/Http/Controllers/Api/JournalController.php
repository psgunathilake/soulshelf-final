<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpsertJournalRequest;
use App\Models\Journal;
use App\Models\Media;
use App\Services\StatsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\ValidationException;

class JournalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Journal::class);

        $filters = $request->validate([
            'from'     => ['sometimes', 'date_format:Y-m-d'],
            'to'       => ['sometimes', 'date_format:Y-m-d'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = Journal::query()->where('user_id', $request->user()->id);

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
        $journal = Journal::where('user_id', $request->user()->id)
            ->where('date', $date)
            ->firstOrFail();

        $this->authorize('view', $journal);

        return response()->json($journal);
    }

    public function upsert(UpsertJournalRequest $request, string $date, StatsService $stats): JsonResponse
    {
        $userId = $request->user()->id;
        $data   = $request->validated();

        if (! empty($data['linked_media_id'])) {
            $ownsMedia = Media::where('id', $data['linked_media_id'])
                ->where('user_id', $userId)
                ->exists();
            if (! $ownsMedia) {
                throw ValidationException::withMessages([
                    'linked_media_id' => ['You can only link media you own.'],
                ]);
            }
        }

        $journal = Journal::updateOrCreate(
            ['user_id' => $userId, 'date' => $date],
            $data,
        );

        try {
            $stats->recompute($request->user());
        } catch (\Throwable $e) {
            report($e);
        }

        return response()->json(
            $journal,
            $journal->wasRecentlyCreated ? Response::HTTP_CREATED : Response::HTTP_OK,
        );
    }

    public function destroy(Request $request, string $date, StatsService $stats): Response
    {
        $journal = Journal::where('user_id', $request->user()->id)
            ->where('date', $date)
            ->firstOrFail();

        $this->authorize('delete', $journal);

        $journal->delete();

        try {
            $stats->recompute($request->user());
        } catch (\Throwable $e) {
            report($e);
        }

        return response()->noContent();
    }
}
