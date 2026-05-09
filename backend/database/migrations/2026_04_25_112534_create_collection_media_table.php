<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('collection_media', function (Blueprint $table) {
            $table->foreignId('collection_id')->constrained('collections')->cascadeOnDelete();
            $table->foreignId('media_id')->constrained('media')->cascadeOnDelete();
            $table->timestamp('created_at')->useCurrent();

            $table->primary(['collection_id', 'media_id']);
            $table->index('media_id', 'collection_media_media_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('collection_media');
    }
};
