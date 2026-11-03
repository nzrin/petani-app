import 'package:petani/project/models/project_form_data.dart';

/// Official source scope and review details: assets/data/crop_variety_sources.json.
class CropVarietyCatalog {
  CropVarietyCatalog._();

  // Jabatan Pertanian SPBT, November 2023. MP codes are registration numbers.
  static const banana = <CropVariety>[
    CropVariety(code: 'MP1', name: 'Awak'),
    CropVariety(code: 'MP2', name: 'Nangka'),
    CropVariety(code: 'MP3', name: 'Mas'),
    CropVariety(code: 'MP4', name: 'Berangan'),
    CropVariety(code: 'MP5', name: 'Nipah'),
    CropVariety(code: 'MP12', name: 'Lang'),
    CropVariety(code: 'MP14', name: 'Cavendish'),
  ];

  // MPOB: the commercial Dura x Pisifera cross, not a supplier certification.
  static const oilPalm = <CropVariety>[
    CropVariety(code: 'DxP', name: 'Tenera'),
  ];

  // LGM Group 1 clones listed by RISDA. Names also serve as stable app keys.
  static const rubber = <CropVariety>[
    CropVariety(code: 'RRIM 928', name: 'RRIM 928'),
    CropVariety(code: 'RRIM 2001', name: 'RRIM 2001'),
    CropVariety(code: 'RRIM 2002', name: 'RRIM 2002'),
    CropVariety(code: 'PB 260', name: 'PB 260'),
    CropVariety(code: 'PB 350', name: 'PB 350'),
  ];

  // DOA recommended cultivars. These keys are names, NOT registration codes.
  static const ginger = <CropVariety>[
    CropVariety(code: 'Bentong', name: 'Bentong'),
    CropVariety(code: 'China', name: 'China'),
    CropVariety(code: 'Tanjung Sepat', name: 'Tanjung Sepat'),
    CropVariety(code: 'Thailand', name: 'Thailand'),
    CropVariety(code: 'Tambunan', name: 'Tambunan'),
    CropVariety(code: 'Bara', name: 'Bara'),
  ];

  // MARDI/KPKM declared varieties; a curated list, not every Malaysian variety.
  static const rice = <CropVariety>[
    CropVariety(code: 'MR 333', name: 'Menora'),
    CropVariety(code: 'MR 326', name: 'Kesidang'),
    CropVariety(code: 'MR 315', name: 'Seri Waja'),
    CropVariety(code: 'MR 307', name: 'MARDI Sebernas 307'),
    CropVariety(code: 'MR 303', name: 'MARDI Sempadan 303'),
    CropVariety(code: 'MR 297', name: 'MARDI Siraj 297'),
    CropVariety(code: 'MR 269', name: 'MR 269'),
    CropVariety(code: 'MR 219', name: 'MR 219'),
    CropVariety(code: 'MR 220 CL2', name: 'MR 220 CL2'),
    CropVariety(code: 'MR CL3', name: 'MR CL3'),
    CropVariety(code: 'MR CL4', name: 'MR CL4'),
    CropVariety(code: 'MRQ 76', name: 'MRQ 76'),
    CropVariety(code: 'MRQ 104', name: 'Kembang Sari'),
  ];

  // Colour forms documented in Sains Malaysiana 45(4), 2016, pp. 507–515.
  // These names are colour categories, not certified registration codes.
  static const torchGinger = <CropVariety>[
    CropVariety(code: 'Merah Jambu', name: 'Merah Jambu'),
    CropVariety(code: 'Merah', name: 'Merah'),
    CropVariety(code: 'Putih', name: 'Putih'),
  ];

  // Preserve existing records until the user selects their actual colour.
  static const legacyTorchGinger = CropVariety(
    code: 'Belum dikenal pasti',
    name: 'Belum dikenal pasti',
  );

  // Curated DOA/MARDI choices; source scope is recorded in the JSON above.
  // Names used as keys are cultivar names, not invented registration numbers.
  static const corn = <CropVariety>[
    CropVariety(code: 'Masmadu', name: 'Masmadu'),
    CropVariety(code: 'Hybrid No 5', name: 'Hybrid No 5'),
    CropVariety(code: 'Thai Super Sweet', name: 'Thai Super Sweet'),
  ];

  static const cassava = <CropVariety>[
    CropVariety(code: 'Sri Pontian', name: 'Sri Pontian'),
    CropVariety(code: 'Sri Kanji 1', name: 'Sri Kanji 1'),
    CropVariety(code: 'Sri Kanji 2', name: 'Sri Kanji 2'),
  ];

  static const sweetPotato = <CropVariety>[
    CropVariety(code: 'Gendut', name: 'Gendut'),
    CropVariety(code: 'Jalur Mas', name: 'Jalur Mas'),
    CropVariety(code: 'Telong', name: 'Telong'),
    CropVariety(code: 'Vitato', name: 'Vitato'),
    CropVariety(code: 'Anggun 1', name: 'Anggun 1'),
    CropVariety(code: 'Anggun 2', name: 'Anggun 2'),
    CropVariety(code: 'Anggun 3', name: 'Anggun 3'),
    CropVariety(code: 'Lembayung', name: 'Lembayung'),
  ];

  static const durian = <CropVariety>[
    CropVariety(code: 'D24', name: 'D24'),
    CropVariety(code: 'D99', name: 'Kop Kecil'),
    CropVariety(code: 'D160', name: 'Buluh Bawah / Tekka'),
    CropVariety(code: 'D168', name: 'Hjh. Hasmah / IOI'),
    CropVariety(code: 'D175', name: 'Udang Merah'),
    CropVariety(code: 'D188', name: 'MDUR78'),
    CropVariety(code: 'D189', name: 'MDUR79'),
    CropVariety(code: 'D190', name: 'MDUR88'),
    CropVariety(code: 'D197', name: 'Raja Kunyit / Musang King'),
    CropVariety(code: 'D200', name: 'Ochee / Duri Hitam'),
  ];

  static const watermelon = <CropVariety>[
    CropVariety(code: 'New Dragon', name: 'New Dragon'),
    CropVariety(code: 'Super Dragon', name: 'Super Dragon'),
    CropVariety(code: 'Flower Dragon', name: 'Flower Dragon'),
  ];

  static const rockMelon = <CropVariety>[
    CropVariety(code: 'CM1', name: 'Glamour'),
  ];

  // Documented Malaysian cultivation in MARDI research; not SPBT certification.
  static const strawberry = <CropVariety>[
    CropVariety(code: 'Festival', name: 'Festival'),
    CropVariety(code: 'Camarosa', name: 'Camarosa'),
    CropVariety(code: 'Monterrey', name: 'Monterrey'),
    CropVariety(code: 'Sweet Sensation', name: 'Sweet Sensation'),
    CropVariety(code: 'Winter Star', name: 'Winter Star'),
    CropVariety(code: 'Albion', name: 'Albion'),
  ];

  static const chilli = <CropVariety>[
    CropVariety(code: 'MC 11', name: 'MC 11'),
    CropVariety(code: 'MC 12', name: 'MC 12'),
    CropVariety(code: 'Bangi', name: 'Bangi'),
    CropVariety(code: 'Kulai', name: 'Kulai'),
    CropVariety(code: 'Cili MARDI', name: 'Cili MARDI'),
  ];

  static const cucumber = <CropVariety>[
    CropVariety(code: 'Simpang Pulai', name: 'Simpang Pulai'),
    CropVariety(code: 'MTi 2', name: 'Tangkak'),
  ];

  static const eggplant = <CropVariety>[
    CropVariety(code: 'Ping Tung Long', name: 'Ping Tung Long'),
    CropVariety(code: 'ARC-BJ-105', name: 'ARC-BJ-105'),
    CropVariety(code: 'MTE 1', name: 'Panjang'),
    CropVariety(code: 'MTE 2', name: 'Bulat'),
  ];

  static String fieldTitle(String cropCode) => switch (cropCode) {
    'rubber_tree' => 'Klon',
    'oil_palm' => 'Bahan Tanaman',
    'ginger' => 'Kultivar',
    'torch_ginger' => 'Varieti (Warna)',
    _ => 'Varieti',
  };
}
