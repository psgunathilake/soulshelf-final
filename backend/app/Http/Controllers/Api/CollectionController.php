<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AttachMediaRequest;
use App\Http\Requests\StoreCollectionRequest;
use App\Http\Requests\UpdateCollectionRequest;
use App\Http\Requests\UploadCoverRequest;
use App\Models\Collection as CollectionModel;
use App\Models\Media;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class CollectionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', CollectionModel::class);

        $perPage = $request->validate([
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ])['per_page'] ?? 20;

        return response()->json(
            CollectionModel::query()
                ->where('user_id', $request->user()->id)
                ->orderByDesc('created_at')
                ->paginate($perPage)
        );
    }

    public function store(StoreCollectionRequest $request): JsonResponse
    {
        $this->authorize('create', CollectionModel::class);

        $collection = $request->user()->collections()->create($request->validated());

        return response()->json($collection, Response::HTTP_CREATED);
    }

    public function show(CollectionModel $collection): JsonResponse
    {
        $this->authorize('view', $collection);

        return response()->json(
            $collection->load('media')
        );
    }

    public function update(UpdateCollectionRequest $request, CollectionModel $collection): JsonResponse
    {
        $this->authorize('update', $collection);

        $collection->update($request->validated());

        return response()->json($collection->refresh());
    }

    public function destroy(CollectionModel $collection): Response
    {
        $this->authorize('delete', $collection);

        $collection->delete();

        return response()->noContent();
    }

    public function attachMedia(AttachMediaRequest $request, CollectionModel $collection): Response
    {
        $this->authorize('update', $collection);

        $userId  = $request->user()->id;
        $mediaId = (int) $request->input('media_id');

        $ownsMedia = Media::where('id', $mediaId)
            ->where('user_id', $userId)
            ->exists();

        if (! $ownsMedia) {
            abort(Response::HTTP_FORBIDDEN, 'You can only attach media you own.');
        }

        $collection->media()->syncWithoutDetaching([$mediaId]);

        return response()->noContent();
    }

    public function detachMedia(Request $request, CollectionModel $collection, int $media): Response
    {
        $this->authorize('update', $collection);

        $userId = $request->user()->id;

        $ownsMedia = Media::where('id', $media)
            ->where('user_id', $userId)
            ->exists();

        if (! $ownsMedia) {
            abort(Response::HTTP_FORBIDDEN, 'You can only detach media you own.');
        }

        $collection->media()->detach($media);

        return response()->noContent();
    }

    public function uploadCover(UploadCoverRequest $request, CollectionModel $collection): JsonResponse
    {
        $this->authorize('update', $collection);

        $path = $request->file('file')->storeAs(
            "users/{$collection->user_id}/collections",
            "{$collection->id}.jpg",
            'public',
        );

        $url = rtrim(config('app.url'), '/') . '/storage/' . $path;
        $collection->update(['cover_url' => $url]);

        return response()->json($collection->refresh());
    }
}
