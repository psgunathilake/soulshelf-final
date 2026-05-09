<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('journals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->longText('content');
            $table->tinyInteger('mood')->default(0);
            $table->tinyInteger('stress')->default(0);
            $table->enum('weather', ['sunny', 'cloudy', 'rainy', 'thunderstorm'])->nullable();
            $table->unsignedTinyInteger('water_cups')->default(0);
            $table->json('todos')->nullable();
            $table->json('birthdays')->nullable();
            $table->foreignId('linked_media_id')->nullable()->constrained('media')->nullOnDelete();
            $table->timestamps();

            $table->unique(['user_id', 'date'], 'journals_user_date_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('journals');
    }
};
