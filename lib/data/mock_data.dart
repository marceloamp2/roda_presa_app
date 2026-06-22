class Rider {
  const Rider({
    required this.initials,
    required this.name,
    required this.motorcycle,
  });

  final String initials;
  final String name;
  final String motorcycle;
}

class Ride {
  const Ride({
    required this.title,
    required this.destination,
    required this.departureName,
    required this.departureDetail,
    required this.time,
    required this.weekday,
    required this.date,
    required this.fullDate,
    required this.distanceKm,
    required this.confirmedCount,
    required this.riders,
    this.hot = false,
    this.canceled = false,
    this.briefing = '09:00',
    this.returnPlan = 'Livre',
    this.tolls = 'R\$ 14,20',
  });

  final String title;
  final String destination;
  final String departureName;
  final String departureDetail;
  final String time;
  final String weekday;
  final String date;
  final String fullDate;
  final int distanceKm;
  final int confirmedCount;
  final List<Rider> riders;
  final bool hot;
  final bool canceled;
  final String briefing;
  final String returnPlan;
  final String tolls;

  String get shareText {
    return '''🏍️ Motorbike 🏍️
🗓️ Data: $fullDate
🚩 $destination
🚏 Local: $destination
⌚ Briefing: $briefing
⏰ Saída: $time
🔙 Volta: $returnPlan
🛣️ Distância: ${distanceKm}km (ida e volta)
📍 Local de partida: $departureName
💵 Pedágios - $tolls
⛽ Abastecer e 🛞 Calibrar antes de sair''';
  }
}

class MockData {
  static const riders = [
    Rider(initials: 'MA', name: 'Marcelo', motorcycle: 'Mirage 250'),
    Rider(initials: 'RB', name: 'Rubão', motorcycle: 'XRE 300'),
    Rider(initials: 'JV', name: 'João V.', motorcycle: 'Fazer 250'),
    Rider(initials: 'LE', name: 'Léo', motorcycle: 'CB 500X'),
  ];

  static const homeRides = [
    Ride(
      title: 'Campos do Jordão',
      destination: 'Campos do Jordão',
      departureName: 'Posto Graal',
      departureDetail: 'Marginal Tietê, SP',
      time: '09:30',
      weekday: 'Sáb',
      date: '27/06',
      fullDate: '27/06 sábado',
      distanceKm: 115,
      confirmedCount: 14,
      hot: true,
      riders: riders,
    ),
    Ride(
      title: 'Santos · orla',
      destination: 'Santos · orla',
      departureName: 'Shell',
      departureDetail: 'Av. dos Bandeirantes',
      time: '07:00',
      weekday: 'Dom',
      date: '28/06',
      fullDate: '28/06 domingo',
      distanceKm: 144,
      confirmedCount: 6,
      riders: riders,
      tolls: 'R\$ 22,40',
    ),
    Ride(
      title: 'Serra do Rio do Rastro',
      destination: 'Serra do Rio do Rastro',
      departureName: 'Posto Trevo',
      departureDetail: 'Anchieta',
      time: '08:15',
      weekday: 'Sáb',
      date: '04/07',
      fullDate: '04/07 sábado',
      distanceKm: 92,
      confirmedCount: 3,
      riders: riders,
      tolls: 'sem pedágio',
    ),
    Ride(
      title: 'Cunha · cachoeiras',
      destination: 'Cunha · cachoeiras',
      departureName: 'Graal Paraibuna',
      departureDetail: 'Rod. Carvalho Pinto',
      time: '06:30',
      weekday: 'Dom',
      date: '05/07',
      fullDate: '05/07 domingo',
      distanceKm: 168,
      confirmedCount: 11,
      hot: true,
      riders: riders,
      tolls: 'R\$ 18,10',
    ),
  ];

  static const awayRides = [
    Ride(
      title: 'Morretes · Graciosa',
      destination: 'Morretes · Graciosa',
      departureName: 'Posto BR',
      departureDetail: 'Av. das Torres',
      time: '08:00',
      weekday: 'Sáb',
      date: '27/06',
      fullDate: '27/06 sábado',
      distanceKm: 88,
      confirmedCount: 19,
      hot: true,
      riders: riders,
    ),
    Ride(
      title: 'Vila Velha · arenitos',
      destination: 'Vila Velha · arenitos',
      departureName: 'Graal',
      departureDetail: 'BR-277',
      time: '07:30',
      weekday: 'Dom',
      date: '28/06',
      fullDate: '28/06 domingo',
      distanceKm: 196,
      confirmedCount: 7,
      riders: riders,
      tolls: 'R\$ 16,00',
    ),
    Ride(
      title: 'Prudentópolis · cachoeiras',
      destination: 'Prudentópolis · cachoeiras',
      departureName: 'Posto Trevo',
      departureDetail: 'Contorno',
      time: '09:00',
      weekday: 'Sáb',
      date: '04/07',
      fullDate: '04/07 sábado',
      distanceKm: 162,
      confirmedCount: 2,
      riders: riders,
    ),
  ];
}
