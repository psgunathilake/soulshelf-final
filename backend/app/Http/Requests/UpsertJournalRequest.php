<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpsertJournalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'content'         => ['required', 'string'],
            'mood'            => ['nullable', 'integer', 'between:0,5'],
            'stress'          => ['nullable', 'integer', 'between:0,5'],
            'weather'         => ['nullable', 'in:sunny,cloudy,rainy,thunderstorm'],
            'water_cups'      => ['nullable', 'integer', 'between:0,255'],
            'todos'           => ['nullable', 'array'],
            'birthdays'       => ['nullable', 'array'],
            'linked_media_id' => ['nullable', 'integer', 'exists:media,id'],
        ];
    }
}
