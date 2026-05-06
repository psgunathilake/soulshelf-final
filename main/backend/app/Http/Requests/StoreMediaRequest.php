<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreMediaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'title'      => ['required', 'string', 'max:200'],
            'category'   => ['required', 'in:book,song,show'],
            'sub_type'   => ['nullable', 'in:movie,tv_show,anime'],
            'genre'      => ['required', 'string', 'max:80'],
            'rating'     => ['nullable', 'integer', 'between:0,5'],
            'status'     => ['required', 'in:planned,ongoing,completed'],
            'cover_url'  => ['nullable', 'string', 'max:500'],
            'reflection' => ['nullable', 'string'],
            'start_date' => ['nullable', 'date'],
            'end_date'   => ['nullable', 'date', 'after_or_equal:start_date'],
            'details'    => ['nullable', 'array'],
        ];
    }
}
