<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'name'        => ['sometimes', 'string', 'max:80'],
            'bio'         => ['nullable', 'string', 'max:500'],
            'preferences' => ['nullable', 'array'],
        ];
    }
}
