extends Node2D

const TOTAL_PETAK = 36
const PETAK_NEGARA = 20
const PETAK_LAIN = 16
const JUMLAH_PEMAIN = 4  # Jumlah pemain selalu 4

# Data petak
var petak = [
	# Sisi bawah
	"Start", "Indonesia", "Malaysia", "Chance", "Thailand", "Airport", "Singapura", "Chance", "Vietnam",
	# Sisi kanan
	"Masuk Penjara", "Filipina", "Brunei Darussalam", "Chance", "Laos", "Kamboja", "Myanmar", "Chance", "Kuwait",
	# Sisi atas 
	"Perpustakaan", "Jepang", "Korea Selatan", "Chance", "Tiongkok", "India", "Chance", "Nepal", "Pakistan",
	# Sisi kiri
	"Harbor", "Iran", "Chance", "Irak", "Turki", "Chance", "Jerman", "Inggris", "Amerika Serikat"
]

# Soal edukasi
var soal = [
	{
		"pertanyaan": "Apa sistem pemerintahan Indonesia?",
		"jawaban": ["Presidensial", "Parlementer", "Monarki", "Diktator"],
		"benar": 0
	},
	{
		"pertanyaan": "Negara mana yang memiliki monarki konstitusional?",
		"jawaban": ["Jepang", "Amerika Serikat", "Tiongkok", "India"],
		"benar": 0
	},

]

# Data pemain
var pemain = []
var pemain_saat_ini = 0
var posisi_pemain = []
var skor_pemain = []

# Node UI 
@onready var tombol_dadu = $UI/TombolDadu
@onready var label_umpan_balik = $UI/LabelUmpanBalik
@onready var nama_pemain = [
	$UI/Player1/NamaPemain1,
	$UI/Player2/NamaPemain2,
	$UI/Player3/NamaPemain3,
	$UI/Player4/NamaPemain4
]
@onready var poin_pemain = [
	$UI/Player1/PoinPemain1,
	$UI/Player2/PoinPemain2,
	$UI/Player3/PoinPemain3,
	$UI/Player4/PoinPemain4
]

# Preload scene QuizPopup
var quiz_popup_scene = preload("res://scenes/QuizPopup.tscn")
var current_quiz_popup = null

# Sprite pion
var sprite_pion = [
	"res://assets/flags/pion1.png",
	"res://assets/flags/pion2.png",
	"res://assets/flags/pion3.png",
	"res://assets/flags/pion4.png"
]

# Posisi petak
var posisi_petak = []

func _ready():
	# Inisialisasi posisi petak untuk tata letak persegi
	var board_pos = Vector2(640, 360) # Pusat papan di layar
	var board_size = 600 # Ukuran papan 
	var corner_size = 100 # Ukuran petak sudut
	var regular_size = 62 # Ukuran petak biasa
	
	# Hitung offset untuk memusatkan papan
	var total_side_length = corner_size + (regular_size * 8) 
	var offset = (board_size - total_side_length) / 2 
	
	# Sisi bawah (kiri ke kanan): Start (sudut) + 8 petak biasa
	posisi_petak.append(board_pos + Vector2(-board_size/2 + corner_size/2 + offset, board_size/2 - corner_size/2 - offset)) # Start
	for i in range(8):
		var x = -board_size/2 + corner_size + (regular_size * (i + 0.5)) + offset
		var y = board_size/2 - regular_size/2 - offset
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Sisi kanan (bawah ke atas): Masuk Penjara (sudut) + 8 petak biasa
	posisi_petak.append(board_pos + Vector2(board_size/2 - corner_size/2 - offset, board_size/2 - corner_size/2 - offset)) # Masuk Penjara
	for i in range(8):
		var x = board_size/2 - regular_size/2 - offset
		var y = board_size/2 - corner_size - (regular_size * (i + 0.5)) - offset
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Sisi atas (kanan ke kiri): Perpustakaan (sudut) + 8 petak biasa
	posisi_petak.append(board_pos + Vector2(board_size/2 - corner_size/2 - offset, -board_size/2 + corner_size/2 + offset)) # Perpustakaan
	for i in range(8):
		var x = board_size/2 - corner_size - (regular_size * (i + 0.5)) - offset
		var y = -board_size/2 + regular_size/2 + offset
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Sisi kiri (atas ke bawah): Harbor (sudut) + 8 petak biasa
	posisi_petak.append(board_pos + Vector2(-board_size/2 + corner_size/2 + offset, -board_size/2 + corner_size/2 + offset)) # Harbor
	for i in range(8):
		var x = -board_size/2 + regular_size/2 + offset
		var y = -board_size/2 + corner_size + (regular_size * (i + 0.5)) + offset
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Acak petak menggunakan Fisher-Yates (kecuali petak sudut)
	var petak_acak = petak.duplicate()
	petak_acak[0] = "Start" # Tetap
	petak_acak[9] = "Masuk Penjara" # Tetap
	petak_acak[18] = "Perpustakaan" # Tetap
	petak_acak[27] = "Harbor" # Tetap
	var petak_lain = []
	for i in range(TOTAL_PETAK):
		if i not in [0, 9, 18, 27]: # Kecualikan petak sudut
			petak_lain.append(petak_acak[i])
	petak_lain = fisher_yates_shuffle(petak_lain)
	var idx = 0
	for i in range(TOTAL_PETAK):
		if i not in [0, 9, 18, 27]:
			petak_acak[i] = petak_lain[idx]
			idx += 1
	petak = petak_acak
	
	# Acak soal
	soal = fisher_yates_shuffle(soal.duplicate())
	
	# Atur UI
	tombol_dadu.connect("pressed", Callable(self, "_on_dadu_dilepas"))
	
	# Langsung atur 4 pemain
	atur_pemain()

func fisher_yates_shuffle(array):
	var n = array.size()
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp
	return array

func atur_pemain():
	pemain.clear()
	posisi_pemain.clear()
	skor_pemain.clear()
	
	# Langsung atur 4 pemain dengan nama default dan pion yang sudah ditentukan
	for i in range(JUMLAH_PEMAIN):
		pemain.append({
			"nama": "Pemain " + str(i + 1),  # Nama default: Pemain 1, Pemain 2, dst.
			"pion": sprite_pion[i],  # Pion ditentukan berdasarkan indeks
			"node": buat_pion(sprite_pion[i], i)
		})
		posisi_pemain.append(0) # Mulai di petak 0 (Start)
		skor_pemain.append(0) # Mulai dengan 0 poin
	
	# Perbarui UI untuk giliran pertama
	perbarui_ui_giliran()

func buat_pion(sprite_path, idx_pemain):
	var pion = Sprite2D.new()
	pion.texture = load(sprite_path)
	# Sesuaikan offset agar pion terlihat jelas di petak sudut maupun biasa
	pion.position = posisi_petak[0] + Vector2(20 * idx_pemain - 30, 0) # Offset untuk visibilitas
	add_child(pion)
	return pion

func _on_dadu_dilepas():
	# Nonaktifkan tombol dadu selama animasi atau pop-up
	tombol_dadu.disabled = true
	
	# lempar dadu (1 sampai 6) dengan Fisher-Yates shuffle
	var opsi_dadu = [1, 2, 3, 4, 5, 6]
	opsi_dadu = fisher_yates_shuffle(opsi_dadu)
	var hasil = opsi_dadu[0]
	
	# Gerakkan pemain
	var posisi_baru = (posisi_pemain[pemain_saat_ini] + hasil) % TOTAL_PETAK
	posisi_pemain[pemain_saat_ini] = posisi_baru
	pemain[pemain_saat_ini]["node"].position = posisi_petak[posisi_baru] + Vector2(20 * pemain_saat_ini - 30, 0)
	
	# Tangani aksi petak
	await tangani_aksi_petak(posisi_baru)

func tangani_aksi_petak(idx_petak):
	var petak_saat_ini = petak[idx_petak]
	if petak_saat_ini in ["Start", "Masuk Penjara", "Perpustakaan", "Harbor", "Airport"]:
		# Petak sudut: Bonus atau aksi khusus
		if petak_saat_ini == "Start":
			skor_pemain[pemain_saat_ini] += 50
			label_umpan_balik.text = "Lewat Start: +50 poin!"
		elif petak_saat_ini == "Masuk Penjara":
			label_umpan_balik.text = "Di Penjara! Lewati 1 giliran."
			# Implementasi lewati giliran bisa ditambahkan
		else:
			skor_pemain[pemain_saat_ini] += 20
			label_umpan_balik.text = petak_saat_ini + ": +20 poin!"
	elif petak_saat_ini in ["Indonesia", "Malaysia", "Singapura", "Thailand", "Filipina", "Vietnam", "Brunei Darussalam", "Myanmar", "Kamboja", "Laos", "Jepang", "Korea Selatan", "Tiongkok", "India", "Pakistan", "Nepal", "Kuwait", "Amerika Serikat", "Inggris", "Jerman", "Iran", "Irak", "Turki"]:
		# Petak negara: Tampilkan pop-up pertanyaan edukasi
		var jawaban_benar = await tampilkan_pertanyaan()
		if jawaban_benar:
			skor_pemain[pemain_saat_ini] += 100
			label_umpan_balik.text = "Benar! +100 poin!"
		else:
			label_umpan_balik.text = "Jawaban salah."
	elif petak_saat_ini == "Chance":
		# Petak Chance: Berikan poin acak atau aksi khusus
		var poin_acak = randi() % 50 + 10
		if randf() > 0.5:  # 50% peluang mendapatkan poin positif
			skor_pemain[pemain_saat_ini] += poin_acak
			label_umpan_balik.text = "Chance: +" + str(poin_acak) + " poin!"
		else:  # 50% peluang penalti
			skor_pemain[pemain_saat_ini] -= poin_acak
			label_umpan_balik.text = "Chance: -" + str(poin_acak) + " poin!"
	
	# Tunggu sebentar untuk menampilkan umpan balik
	await get_tree().create_timer(2.0).timeout
	giliran_berikutnya()

func tampilkan_pertanyaan():
	if soal.size() == 0:
		label_umpan_balik.text = "Tidak ada soal lagi!"
		return false
	
	# Ambil soal
	var s = soal.pop_front()
	
	# Acak opsi jawaban
	var jawaban_acak = fisher_yates_shuffle(s.jawaban.duplicate())
	var idx_benar = jawaban_acak.find(s.jawaban[s.benar])
	
	# Instansiasi pop-up
	current_quiz_popup = quiz_popup_scene.instantiate()
	add_child(current_quiz_popup)
	current_quiz_popup.setup(s.pertanyaan, jawaban_acak, idx_benar)
	
	# Tunggu jawaban dari pop-up
	var jawaban_benar = await current_quiz_popup.quiz_answered
	
	# Hapus pop-up setelah jawaban dipilih
	current_quiz_popup.queue_free()
	current_quiz_popup = null
	
	return jawaban_benar

func giliran_berikutnya():
	pemain_saat_ini = (pemain_saat_ini + 1) % JUMLAH_PEMAIN
	label_umpan_balik.text = ""
	perbarui_ui_giliran()
	# Aktifkan kembali tombol dadu
	tombol_dadu.disabled = false

func perbarui_ui_giliran():
	tombol_dadu.text = pemain[pemain_saat_ini]["nama"] + ": Lempar Dadu"
	for i in range(JUMLAH_PEMAIN):
		nama_pemain[i].text = pemain[i]["nama"]
		poin_pemain[i].text = "Poin: " + str(skor_pemain[i])
