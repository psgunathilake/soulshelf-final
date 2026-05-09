<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title', 200);
            $table->enum('category', ['book', 'song', 'show']);
            $table->enum('sub_type', ['movie', 'tv_show', 'anime'])->nullable();
            $table->string('genre', 80);
            $table->unsignedTinyInteger('rating')->default(0);
            $table->enum('status', ['planned', 'ongoing', 'completed']);
            $table->string('cover_url', 500)->nullable();
            $table->text('reflection')->nullable();
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->json('details')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'category', 'rating'], 'media_user_cat_rating_idx');
            $table->index(['user_id', 'category', 'status', 'created_at'], 'media_user_cat_status_created_idx');
            $table->index(['user_id', 'category', 'genre'], 'media_user_cat_genre_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media');
    }
};
