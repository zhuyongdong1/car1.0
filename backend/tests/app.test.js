const request = require('supertest');
const express = require('express');

jest.mock('../models', () => ({
  Car: {
    create: jest.fn(),
    findOne: jest.fn(),
  },
  Repair: {},
  WashLog: {}
}));

const { Car } = require('../models');
const carsRouter = require('../routes/cars');

const app = express();
app.use(express.json());
app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});
app.use('/api/cars', carsRouter);

describe('Backend API routes', () => {
  beforeEach(() => jest.clearAllMocks());

  test('GET /health returns OK', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ status: 'OK' });
  });

  test('POST /api/cars creates a car', async () => {
    const carData = { plate_number: 'abc123', vin: 'vin1234567890123' };
    Car.create.mockResolvedValue({ id: 1, ...carData });

    const res = await request(app).post('/api/cars').send(carData);
    expect(res.statusCode).toBe(201);
    expect(Car.create).toHaveBeenCalledWith(
      expect.objectContaining({
        plate_number: 'ABC123',
        vin: 'VIN1234567890123'
      })
    );
    expect(res.body.success).toBe(true);
  });

  test('GET /api/cars/:plate_number not found', async () => {
    Car.findOne.mockResolvedValue(null);
    const res = await request(app).get('/api/cars/ABC123');
    expect(res.statusCode).toBe(404);
    expect(res.body.code).toBe('CAR_NOT_FOUND');
  });
});
