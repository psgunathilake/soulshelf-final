<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class FileController extends Controller
{
    public function destroy(Request $request): Response
    {
        $data = $request->validate([
            'path' => ['required', 'string', 'max:500'],
        ]);

        $path   = $data['path'];
        $prefix = "users/{$request->user()->id}/";

        if (str_contains($path, '..') || ! Str::startsWith($path, $prefix)) {
            abort(Response::HTTP_FORBIDDEN, 'Path is outside your storage tree.');
        }

        Storage::disk('public')->delete($path);

        return response()->noContent();
    }
}
