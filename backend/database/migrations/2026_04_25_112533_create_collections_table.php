<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('collections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 120);
            $table->text('description')->nullable();
            $table->string('cover_url', 500)->nullable();
            $table->timestamps();

            $table->index(['user_id', 'name'], 'collections_user_name_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('collections');
    }
};
