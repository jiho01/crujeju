import 'package:flutter/material.dart';

class CruiseOption {
  const CruiseOption({
    required this.id,
    required this.shipName,
    required this.company,
    required this.port,
    required this.date,
    required this.arrival,
    required this.departure,
    required this.capacity,
  });

  final String id;
  final String shipName;
  final String company;
  final String port;
  final String date;
  final String arrival;
  final String departure;
  final String capacity;
}

class OnboardingData {
  const OnboardingData({
    required this.language,
    required this.currency,
    required this.travelerCount,
    required this.cruise,
    required this.interests,
    required this.transport,
  });

  final String language;
  final String currency;
  final int travelerCount;
  final CruiseOption cruise;
  final List<String> interests;
  final String transport;
}

class Guide {
  const Guide({
    required this.id,
    required this.name,
    required this.image,
    required this.badge,
    required this.match,
    required this.rating,
    required this.reviewCount,
    required this.languages,
    required this.price,
    required this.tags,
    required this.carSeats,
    required this.intro,
    required this.style,
  });

  final String id;
  final String name;
  final String image;
  final String badge;
  final int match;
  final double rating;
  final int reviewCount;
  final List<String> languages;
  final int price;
  final List<String> tags;
  final int carSeats;
  final String intro;
  final String style;
}

class GuideReview {
  const GuideReview({
    required this.guideId,
    required this.author,
    required this.country,
    required this.rating,
    required this.date,
    required this.cruise,
    required this.content,
  });

  final String guideId;
  final String author;
  final String country;
  final int rating;
  final String date;
  final String cruise;
  final String content;
}

class GuideMessage {
  const GuideMessage({
    required this.text,
    required this.fromUser,
    required this.time,
  });

  final String text;
  final bool fromUser;
  final String time;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.image,
    required this.category,
    required this.rating,
    required this.fromPort,
    required this.stayTime,
    required this.crowd,
    required this.description,
    required this.hours,
    required this.location,
    required this.paymentCount,
    this.benefit,
    this.guidePick = false,
  });

  final String id;
  final String name;
  final String image;
  final String category;
  final double rating;
  final int fromPort;
  final int stayTime;
  final String crowd;
  final String description;
  final String hours;
  final String location;
  final int paymentCount;
  final String? benefit;
  final bool guidePick;
}

class PaymentRecord {
  const PaymentRecord({
    required this.store,
    required this.category,
    required this.time,
    required this.amount,
    required this.icon,
    this.isCharge = false,
  });

  final String store;
  final String category;
  final String time;
  final int amount;
  final IconData icon;
  final bool isCharge;
}
