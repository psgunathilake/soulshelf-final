<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CollectionController;
use App\Http\Controllers\Api\FileController;
use App\Http\Controllers\Api\JournalController;
use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\PlannerController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    // Public endpoints
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);

    // Email verification (signed URL — public but signature-protected)
    Route::get('email/verify/{id}/{hash}', [AuthController::class, 'verifyEmail'])
        ->middleware('signed')
        ->name('verification.verify');

    // Authenticated endpoints
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::post('email/resend', [AuthController::class, 'resendVerification']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('media', MediaController::class)
        ->parameters(['media' => 'media']);
    Route::post('media/{media}/cover', [MediaController::class, 'uploadCover']);

    Route::put   ('user',            [UserController::class, 'updateProfile']);
    Route::get   ('user/stats',      [UserController::class, 'stats']);
    Route::put   ('user/pin',        [UserController::class, 'setPin']);
    Route::post  ('user/pin/verify', [UserController::class, 'verifyPin']);
    Route::post  ('user/avatar',     [UserController::class, 'uploadAvatar']);
    Route::post  ('user/header',     [UserController::class, 'uploadHeader']);

    Route::delete('files',       [FileController::class, 'destroy']);

    Route::get   ('journals',        [JournalController::class, 'index']);
    Route::get   ('journals/{date}', [JournalController::class, 'show'])->where('date', '\d{4}-\d{2}-\d{2}');
    Route::put   ('journals/{date}', [JournalController::class, 'upsert'])->where('date', '\d{4}-\d{2}-\d{2}');
    Route::delete('journals/{date}', [JournalController::class, 'destroy'])->where('date', '\d{4}-\d{2}-\d{2}');

    Route::get   ('planners',        [PlannerController::class, 'index']);
    Route::get   ('planners/{date}', [PlannerController::class, 'show'])->where('date', '\d{4}-\d{2}-\d{2}');
    Route::put   ('planners/{date}', [PlannerController::class, 'upsert'])->where('date', '\d{4}-\d{2}-\d{2}');
    Route::delete('planners/{date}', [PlannerController::class, 'destroy'])->where('date', '\d{4}-\d{2}-\d{2}');

    Route::apiResource('collections', CollectionController::class);
    Route::post  ('collections/{collection}/cover',         [CollectionController::class, 'uploadCover']);
    Route::post  ('collections/{collection}/media',         [CollectionController::class, 'attachMedia']);
    Route::delete('collections/{collection}/media/{media}', [CollectionController::class, 'detachMedia']);
});
