<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tickets', function (Blueprint $table) {
            $table->string('id')->primary(); // Custom ID: TK-20260706-001

            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('helpdesk_id')->nullable()->constrained('users')->nullOnDelete();

            $table->string('title');
            $table->text('description');
            $table->string('priority')->default('Medium'); // Low, Medium, High
            $table->string('attachment')->nullable(); // Upload file (Gambar/PDF)

            $table->enum('status', ['open', 'assign', 'in progress', 'close'])->default('open');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tickets');
    }
};
