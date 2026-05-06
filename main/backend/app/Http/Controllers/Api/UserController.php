<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\SetPinRequest;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Requests\UploadAvatarRequest;
use App\Http\Requests\UploadHeaderRequest;
use App\Http\Requests\VerifyPinRequest;
use App\Services\StatsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class UserController extends Controller
{
    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->update($request->validated());

        return response()->json($user->refresh());
    }

    public function setPin(SetPinRequest $request): Response
    {
        $request->user()->update([
            'pin_hash' => $request->validated()['pin_hash'],
        ]);

        return response()->noContent();
    }

    public function verifyPin(VerifyPinRequest $request): JsonResponse
    {
        $stored = $request->user()->pin_hash;
        $submitted = $request->validated()['pin_hash'];

        // Wrong PIN is expected user behaviour, not a validation error —
        // return 200 with a boolean instead of 422 so the Flutter side
        // doesn't have to catch DioException for the common case.
        return response()->json([
            'valid' => $stored !== null && hash_equals($stored, $submitted),
        ]);
    }

    public function uploadAvatar(UploadAvatarRequest $request): JsonResponse
    {
        $user = $request->user();

        $path = $request->file('file')->storeAs(
            "users/{$user->id}/profile",
            'avatar.jpg',
            'public',
        );

        $url = rtrim(config('app.url'), '/') . '/storage/' . $path;
        $user->update(['photo_url' => $url]);

        return response()->json($user->refresh());
    }

    public function uploadHeader(UploadHeaderRequest $request): JsonResponse
    {
        $user = $request->user();

        $path = $request->file('file')->storeAs(
            "users/{$user->id}/profile",
            'header.jpg',
            'public',
        );

        $url = rtrim(config('app.url'), '/') . '/storage/' . $path;
        $user->update(['header_url' => $url]);

        return response()->json($user->refresh());
    }

    public function stats(Request $request, StatsService $stats): JsonResponse
    {
        $user    = $request->user();
        $current = $user->stats;

        if (empty($current)) {
            $current = $stats->recompute($user);
        }

        return response()->json($current);
    }
}
