<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpsertPlannerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'schedule'   => ['nullable', 'array'],
            'priorities' => ['nullable', 'array'],
            'notes'      => ['nullable', 'string'],
        ];
    }
}
