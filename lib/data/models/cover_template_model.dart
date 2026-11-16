/// Model and predefined registry for notebook covers.
class CoverTemplate {
  final String id;
  final String name;
  final String category;
  final String primaryColorHex;
  final String accentColorHex;
  final String
  patternType; // 'leather' | 'linen' | 'geometric' | 'gradient' | 'floral' | 'nature' | 'minimal' | 'academic' | 'abstract'
  final String description;
  final String? customImagePath;

  const CoverTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.patternType,
    this.description = '',
    this.customImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'primaryColorHex': primaryColorHex,
      'accentColorHex': accentColorHex,
      'patternType': patternType,
      'description': description,
      'customImagePath': customImagePath,
    };
  }

  factory CoverTemplate.fromJson(Map<String, dynamic> json) {
    return CoverTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      primaryColorHex: json['primaryColorHex'] as String,
      accentColorHex: json['accentColorHex'] as String,
      patternType: json['patternType'] as String,
      description: json['description'] as String? ?? '',
      customImagePath: json['customImagePath'] as String?,
    );
  }

  CoverTemplate copyWith({
    String? id,
    String? name,
    String? category,
    String? primaryColorHex,
    String? accentColorHex,
    String? patternType,
    String? description,
    String? customImagePath,
  }) {
    return CoverTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      patternType: patternType ?? this.patternType,
      description: description ?? this.description,
      customImagePath: customImagePath ?? this.customImagePath,
    );
  }
}

/// Curated library of cover designs across all supported categories.
class CoverRegistry {
  static const List<CoverTemplate> builtInCovers = [
    // Dark Academia
    CoverTemplate(
      id: 'dark_academia_leather',
      name: 'Oxford Leather',
      category: 'Dark Academia',
      primaryColorHex: '#1E2A38',
      accentColorHex: '#D4AF37',
      patternType: 'leather',
      description: 'Deep navy calfskin with gilded gold embossing',
    ),
    CoverTemplate(
      id: 'dark_academia_burgundy',
      name: 'Cambridge Velvet',
      category: 'Dark Academia',
      primaryColorHex: '#4A1521',
      accentColorHex: '#E5C158',
      patternType: 'leather',
      description: 'Rich burgundy antique bound with gold spine ribs',
    ),

    // Minimalist
    CoverTemplate(
      id: 'minimalist_cream',
      name: 'Pure Linen Cream',
      category: 'Minimalist',
      primaryColorHex: '#F4EFE6',
      accentColorHex: '#8C7B6D',
      patternType: 'linen',
      description: 'Warm cream bookcloth linen with subtle textured weave',
    ),
    CoverTemplate(
      id: 'minimalist_charcoal',
      name: 'Monolith Charcoal',
      category: 'Minimalist',
      primaryColorHex: '#2B2B2B',
      accentColorHex: '#888888',
      patternType: 'minimal',
      description: 'Smooth matte charcoal with silver debossed accents',
    ),

    // Academic
    CoverTemplate(
      id: 'academic_navy',
      name: 'Scholar Blue',
      category: 'Academic',
      primaryColorHex: '#1B365D',
      accentColorHex: '#B58500',
      patternType: 'academic',
      description: 'Classic university buckram cloth with gold emblem border',
    ),
    CoverTemplate(
      id: 'academic_forest',
      name: 'Ivory League Green',
      category: 'Academic',
      primaryColorHex: '#1C3F30',
      accentColorHex: '#C5A059',
      patternType: 'academic',
      description: 'Traditional library cloth bound in dark forest green',
    ),

    // Floral & Botanical
    CoverTemplate(
      id: 'floral_rose',
      name: 'Vintage Rosewood',
      category: 'Floral',
      primaryColorHex: '#8C485A',
      accentColorHex: '#F7D6DC',
      patternType: 'floral',
      description:
          'Delicate Victorian rose botanical illustrations and blush foil',
    ),
    CoverTemplate(
      id: 'floral_lavender',
      name: 'Wildflower Field',
      category: 'Floral',
      primaryColorHex: '#6F5C7A',
      accentColorHex: '#E8DFF5',
      patternType: 'floral',
      description: 'Pressed lavender stems against woven lilac cloth',
    ),

    // Pastel
    CoverTemplate(
      id: 'pastel_peach',
      name: 'Peach Bellini',
      category: 'Pastel',
      primaryColorHex: '#E8927C',
      accentColorHex: '#FFF0EC',
      patternType: 'linen',
      description: 'Soft pastel coral with subtle sun-washed paper texture',
    ),
    CoverTemplate(
      id: 'pastel_sage',
      name: 'Misty Sage',
      category: 'Pastel',
      primaryColorHex: '#8A9E8E',
      accentColorHex: '#EAF0EB',
      patternType: 'linen',
      description: 'Subtle eucalyptus and muted green stationery cloth',
    ),

    // Professional
    CoverTemplate(
      id: 'professional_executive',
      name: 'Executive Onyx',
      category: 'Professional',
      primaryColorHex: '#1F2421',
      accentColorHex: '#A2A79E',
      patternType: 'leather',
      description: 'Brushed Italian leather with precision-stitched perimeter',
    ),
    CoverTemplate(
      id: 'professional_slate',
      name: 'Architect Slate',
      category: 'Professional',
      primaryColorHex: '#3D4554',
      accentColorHex: '#9BAEC8',
      patternType: 'linen',
      description: 'Heavy duty tech-linen binding for engineers and architects',
    ),

    // Nature
    CoverTemplate(
      id: 'nature_earth',
      name: 'Terracotta Clay',
      category: 'Nature',
      primaryColorHex: '#9E4731',
      accentColorHex: '#F0D5BA',
      patternType: 'nature',
      description: 'Warm earthen pigment with natural organic textures',
    ),
    CoverTemplate(
      id: 'nature_moss',
      name: 'Cedar Pine',
      category: 'Nature',
      primaryColorHex: '#284B35',
      accentColorHex: '#A9C4A6',
      patternType: 'nature',
      description: 'Pacific Northwest evergreen bark and cedar tone',
    ),

    // Geometric
    CoverTemplate(
      id: 'geometric_bauhaus',
      name: 'Bauhaus Grid',
      category: 'Geometric',
      primaryColorHex: '#2C3E50',
      accentColorHex: '#E74C3C',
      patternType: 'geometric',
      description:
          'Modernist mathematical proportions and clean geometric lines',
    ),
    CoverTemplate(
      id: 'geometric_hex',
      name: 'Honeycomb Gilt',
      category: 'Geometric',
      primaryColorHex: '#202020',
      accentColorHex: '#F1C40F',
      patternType: 'geometric',
      description: 'Gilded hexagonal tessellation against matte black',
    ),

    // Gradient
    CoverTemplate(
      id: 'gradient_twilight',
      name: 'Twilight Aurum',
      category: 'Gradient',
      primaryColorHex: '#3A1C71',
      accentColorHex: '#FFAF7B',
      patternType: 'gradient',
      description: 'Smooth twilight violet dissolving into morning peach gold',
    ),
    CoverTemplate(
      id: 'gradient_oceanic',
      name: 'Oceanic Depths',
      category: 'Gradient',
      primaryColorHex: '#0F2027',
      accentColorHex: '#2C5364',
      patternType: 'gradient',
      description: 'Calm deep sea abyssal turquoise gradient',
    ),

    // Abstract
    CoverTemplate(
      id: 'abstract_marbled',
      name: 'Venetian Marble',
      category: 'Abstract',
      primaryColorHex: '#483D8B',
      accentColorHex: '#D8BFD8',
      patternType: 'abstract',
      description: 'Hand-swirled water marbling paper with gold mica dusting',
    ),
  ];

  static List<String> get categories => [
    'All',
    'Dark Academia',
    'Minimalist',
    'Academic',
    'Floral',
    'Pastel',
    'Professional',
    'Nature',
    'Geometric',
    'Gradient',
    'Abstract',
  ];

  static CoverTemplate getById(String id) {
    return builtInCovers.firstWhere(
      (c) => c.id == id,
      orElse: () => builtInCovers.first,
    );
  }
}
