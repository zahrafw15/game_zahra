extends CanvasLayer

# Sinyal untuk mengirimkan hasil jawaban
signal quiz_answered(correct)

@onready var label_pertanyaan = $Panel/LabelPertanyaan
@onready var tombol_jawaban = [$Panel/Jawaban1, $Panel/Jawaban2, $Panel/Jawaban3, $Panel/Jawaban4]

# Fungsi untuk mengatur pertanyaan dan opsi jawaban
func setup(pertanyaan, opsi_jawaban, idx_benar):
	label_pertanyaan.text = pertanyaan
	for i in range(4):
		tombol_jawaban[i].text = opsi_jawaban[i]
		tombol_jawaban[i].disabled = false
		# Simpan apakah tombol ini adalah jawaban benar
		if i == idx_benar:
			tombol_jawaban[i].set_meta("benar", true)
		else:
			tombol_jawaban[i].set_meta("benar", false)
		# Hubungkan tombol dengan fungsi jawaban
		if not tombol_jawaban[i].is_connected("pressed", Callable(self, "_on_jawaban_dipilih")):
			tombol_jawaban[i].connect("pressed", Callable(self, "_on_jawaban_dipilih").bind(i))

func _on_jawaban_dipilih(idx_jawaban):
	var apakah_benar = tombol_jawaban[idx_jawaban].get_meta("benar", false)
	# Kirim sinyal dengan hasil jawaban
	emit_signal("quiz_answered", apakah_benar)
	# Nonaktifkan tombol setelah jawaban dipilih
	for btn in tombol_jawaban:
		btn.disabled = true
