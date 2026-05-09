<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SetPinRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            // SHA-256 hex digest from the client. We never see the plaintext
            // PIN — hashing is done client-side in pin_hasher.dart.
            'pin_hash' => ['required', 'string', 'size:64', 'regex:/^[a-f0-9]{64}$/i'],
        ];
    }
}
