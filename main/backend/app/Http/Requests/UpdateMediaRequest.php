<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMediaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'title'      => ['sometimes', 'required', 'string', 'max:200'],
            'category'   => ['sometimes', 'required', 'in:book,song,show'],
            'sub_type'   => ['sometimes', 'nullable', 'in:movie,tv_show,anime'],
            'genre'      => ['sometimes', 'required', 'string', 'max:80'],
            'rating'     => ['sometimes', 'nullable', 'integer', 'between:0,5'],
            'status'     => ['sometimes', 'required', 'in:planned,ongoing,completed'],
            'cover_url'  => ['sometimes', 'nullable', 'string', 'max:500'],
            'reflection' => ['sometimes', 'nullable', 'string'],
            'start_date' => ['sometimes', 'nullable', 'date'],
            'end_date'   => ['sometimes', 'nullable', 'date', 'after_or_equal:start_date'],
            'details'    => ['sometimes', 'nullable', 'array'],
        ];
    }
}
