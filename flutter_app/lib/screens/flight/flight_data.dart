import 'package:flutter_app/models/flight_offer_model.dart';

final List<FlightOfferModel> demoFlightOffers = _mockFlightOffers
    .map((json) => FlightOfferModel.fromJson(json))
    .toList();

const List<Map<String, dynamic>> _mockFlightOffers = [
  {
    'id': 'GA870',
    'source': 'WANDERWHALE',
    'itineraries': [
      {
        'segments': [
          {
            'carrierCode': 'GA',
            'number': '870',
            'departure': {
              'iataCode': 'CGK',
              'terminal': '3',
              'at': '2025-01-18T09:00:00'
            },
            'arrival': {
              'iataCode': 'HND',
              'terminal': '2',
              'at': '2025-01-18T18:00:00'
            },
            'aircraft': {'code': '332'},
            'duration': 'PT7H',
            'operating': {'carrierCode': 'GA'},
            'pricingDetailPerAdult': {
              'travelClass': 'BUSINESS',
              'fareBasis': 'JX1',
              'brandedFare': 'Business Flex',
              'isRefundable': true,
              'isChangeAllowed': true,
            },
          },
        ],
      },
    ],
    'price': {
      'currency': 'IDR',
      'grandTotal': '17500000',
      'base': '15000000',
      'fees': [
        {'amount': '250000', 'type': 'ISSUANCE'}
      ],
      'taxes': [
        {'amount': '2250000', 'type': 'ID'}
      ],
    },
    'validatingAirlineCodes': ['GA'],
    'travelerPricings': [
      {
        'travelerId': '1',
        'travelerType': 'ADULT',
        'price': {'currency': 'IDR', 'total': '17500000', 'base': '15000000'},
      },
    ],
  },
  {
    'id': 'SQ963',
    'source': 'WANDERWHALE',
    'itineraries': [
      {
        'segments': [
          {
            'carrierCode': 'SQ',
            'number': '963',
            'departure': {
              'iataCode': 'CGK',
              'terminal': '3',
              'at': '2025-02-05T13:30:00'
            },
            'arrival': {
              'iataCode': 'SIN',
              'terminal': '1',
              'at': '2025-02-05T16:15:00'
            },
            'aircraft': {'code': '359'},
            'duration': 'PT1H45M',
            'operating': {'carrierCode': 'SQ'},
            'pricingDetailPerAdult': {
              'travelClass': 'ECONOMY',
              'fareBasis': 'YNW',
              'brandedFare': 'Economy Flexi',
              'isRefundable': true,
              'isChangeAllowed': true,
            },
          },
        ],
      },
    ],
    'price': {
      'currency': 'IDR',
      'grandTotal': '4400000',
      'base': '3800000',
      'fees': [
        {'amount': '120000', 'type': 'ISSUANCE'}
      ],
      'taxes': [
        {'amount': '480000', 'type': 'SG'}
      ],
    },
    'validatingAirlineCodes': ['SQ'],
    'travelerPricings': [
      {
        'travelerId': '1',
        'travelerType': 'ADULT',
        'price': {'currency': 'IDR', 'total': '4400000', 'base': '3800000'},
      },
      {
        'travelerId': '2',
        'travelerType': 'ADULT',
        'price': {'currency': 'IDR', 'total': '4400000', 'base': '3800000'},
      },
    ],
  },
  {
    'id': 'GA402',
    'source': 'WANDERWHALE',
    'itineraries': [
      {
        'segments': [
          {
            'carrierCode': 'GA',
            'number': '402',
            'departure': {
              'iataCode': 'CGK',
              'terminal': '3',
              'at': '2025-01-25T07:15:00'
            },
            'arrival': {
              'iataCode': 'DPS',
              'terminal': '1',
              'at': '2025-01-25T10:05:00'
            },
            'aircraft': {'code': '738'},
            'duration': 'PT1H50M',
            'operating': {'carrierCode': 'GA'},
            'pricingDetailPerAdult': {
              'travelClass': 'ECONOMY',
              'fareBasis': 'YID',
              'isRefundable': false,
              'isChangeAllowed': true,
            },
          },
        ],
      },
    ],
    'price': {
      'currency': 'IDR',
      'grandTotal': '2100000',
      'base': '1800000',
      'fees': [
        {'amount': '50000', 'type': 'ISSUANCE'}
      ],
      'taxes': [
        {'amount': '250000', 'type': 'ID'}
      ],
    },
    'validatingAirlineCodes': ['GA'],
    'travelerPricings': [
      {
        'travelerId': '1',
        'travelerType': 'ADULT',
        'price': {'currency': 'IDR', 'total': '2100000', 'base': '1800000'},
      },
    ],
  },
];

