<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMediaRequest;
use App\Http\Requests\UpdateMediaRequest;
use App\Http\Requests\UploadCoverRequest;
use App\Models\Media;
use App\Services\StatsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Media::class);

        $filters = $request->validate([
            'category' => ['sometimes', 'in:book,song,show'],
            'status'   => ['sometimes', 'in:planned,ongoing,completed'],
            'genre'    => ['sometimes', 'string', 'max:80'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = Media::query()->where('user_id', $request->user()->id);

        foreach (['category', 'status', 'genre'] as $field) {
            if (isset($filters[$field])) {
                $query->where($field, $filters[$field]);
            }
        }

        $perPage = $filters['per_page'] ?? 20;

        return response()->json(
            $query->orderByDesc('created_at')->paginate($perPage)
        );
    }

    public function store(StoreMediaRequest $request, StatsService $stats): JsonResponse
    {
        $this->authorize('create', Media::class);

        $media = $request->user()->media()->create($request->validated());

        try {
            $stats->recompute($request->user());
        } catch (\Throwable $e) {
            report($e);
        }

        return response()->json($media, Response::HTTP_CREATED);
    }

    public function show(Media $media): JsonResponse
    {
        $this->authorize('view', $media);

        return response()->json($media);
    }

    public function update(UpdateMediaRequest $request, Media $media, StatsService $stats): JsonResponse
    {
        $this->authorize('update', $media);

        $media->update($request->validated());

        try {
            $stats->recompute($request->user());
        } catch (\Throwable $e) {
            report($e);
        }

        return response()->json($media->refresh());
    }

    public function destroy(Request $request, Media $media, StatsService $stats): Response
    {
        $this->authorize('delete', $media);

        if ($media->cover_url) {
            $relative = "users/{$media->user_id}/covers/{$media->id}.jpg";
            Storage::disk('public')->delete($relative);
        }

        $media->delete();

        try {
            $stats->recompute($request->user());
        } catch (\Throwable $e) {
            report($e);
        }

        return response()->noContent();
    }

    public function uploadCover(UploadCoverRequest $request, Media $media): JsonResponse
    {
        $this->authorize('update', $media);

        $path = $request->file('file')->storeAs(
            "users/{$media->user_id}/covers",
            "{$media->id}.jpg",
            'public',
        );

        $url = rtrim(config('app.url'), '/') . '/storage/' . $path;
        $media->update(['cover_url' => $url]);

        return response()->json($media->refresh());
    }
}
