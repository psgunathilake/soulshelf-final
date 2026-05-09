<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class VerifyPinRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'pin_hash' => ['required', 'string', 'size:64', 'regex:/^[a-f0-9]{64}$/i'],
        ];
    }
}
