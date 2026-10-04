//
//  DemoMode.swift
//  ParkEzy
//
//  Offline demo mode for showcasing the app with no backend or network.
//  While active, SupabaseService serves the data below instead of calling Supabase,
//  and writes (bookings, approvals, new listings) are kept in memory for the session.
//

import Foundation
import CoreLocation

enum DemoMode {

    /// True while the app is running on the built-in demo data.
    private(set) static var isActive = false

    /// Posted when demo mode is switched on or off so view models can reload.
    static let didChangeNotification = Notification.Name("ParkEzyDemoModeDidChange")

    static let driver = AppUser(
        id: DemoData.driverID.uuidString,
        email: "driver@demo.parkezy",
        name: "Aarav Sharma",
        phoneNumber: "+91 98100 12345",
        profileImageURL: nil,
        createdAt: Date().addingTimeInterval(-86400 * 90),
        capabilities: UserCapabilities(canDrive: true, canHostPrivate: false, canHostCommercial: false),
        stats: UserStats(totalBookingsAsDriver: 14, hostRating: nil, totalEarnings: nil)
    )

    static let host = AppUser(
        id: DemoData.hostID.uuidString,
        email: "host@demo.parkezy",
        name: "Meera Kapoor",
        phoneNumber: "+91 98110 54321",
        profileImageURL: nil,
        createdAt: Date().addingTimeInterval(-86400 * 180),
        capabilities: UserCapabilities(canDrive: true, canHostPrivate: true, canHostCommercial: true),
        stats: UserStats(totalBookingsAsDriver: 3, hostRating: 4.8, totalEarnings: 48650)
    )

    /// The signed-in demo user, if any.
    private(set) static var user: AppUser?

    static func enable(as role: UserRole) -> AppUser {
        let demoUser = role == .host ? host : driver
        DemoData.reset()
        user = demoUser
        isActive = true
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
        return demoUser
    }

    static func disable() {
        guard isActive else { return }
        isActive = false
        user = nil
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}

// MARK: - Demo Data

/// In-memory store backing demo mode. Mutations last until the demo is restarted.
enum DemoData {

    static let driverID = UUID(uuidString: "D0000000-0000-4000-8000-000000000001")!
    static let hostID = UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!
    private static let otherHostID = UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!

    static var parkingSpots: [ParkingSpot] = []
    static var privateListings: [PrivateParkingListing] = []
    static var commercialFacilities: [CommercialParkingFacility] = []
    static var privateBookingRequests: [PrivateBooking] = []
    static var commercialBookings: [CommercialBooking] = []
    static var bookingSessions: [BookingSession] = []

    static func reset() {
        parkingSpots = MockDataService.shared.parkingSpots + makeExtraSpots()
        privateListings = makePrivateListings()
        commercialFacilities = makeFacilities()
        privateBookingRequests = makePrivateBookingRequests()
        commercialBookings = makeCommercialBookings()
        bookingSessions = makeBookingSessions()
    }

    // MARK: Map spots

    /// Extra pins so the map looks busy around central/south Delhi and Gurugram.
    private static func makeExtraSpots() -> [ParkingSpot] {
        func spot(_ address: String, _ lat: Double, _ lng: Double, _ type: SpotType, _ price: Double,
                  covered: Bool, ev: Bool, occupied: Bool, rating: Double, reviews: Int) -> ParkingSpot {
            ParkingSpot(
                id: UUID(), address: address,
                coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                type: type, pricePerHour: price, hasCCTV: true, isCovered: covered, hasEVCharging: ev,
                isAccessible: true, is24Hours: true, hasInsurance: type == .mall, isOccupied: occupied,
                rating: rating, reviewCount: reviews,
                accessPIN: type == .privateDriveway ? String(format: "%04d", Int.random(in: 1000...9999)) : nil
            )
        }
        return [
            spot("Ambience Mall Basement, Vasant Kunj", 28.5410, 77.1550, .mall, 90, covered: true, ev: true, occupied: false, rating: 4.7, reviews: 410),
            spot("Pacific Mall, Tagore Garden", 28.6430, 77.1130, .mall, 55, covered: true, ev: false, occupied: false, rating: 4.4, reviews: 263),
            spot("Pacific D21 Mall, Dwarka", 28.5920, 77.0450, .mall, 50, covered: true, ev: true, occupied: true, rating: 4.3, reviews: 176),
            spot("Inorbit Mall Lot, Cyber City", 28.4980, 77.0880, .mall, 75, covered: true, ev: true, occupied: false, rating: 4.6, reviews: 305),
            spot("Driveway, Safdarjung Enclave", 28.5670, 77.2000, .privateDriveway, 50, covered: false, ev: false, occupied: false, rating: 4.5, reviews: 24),
            spot("Garage, Green Park", 28.5594, 77.2063, .privateDriveway, 65, covered: true, ev: false, occupied: false, rating: 4.7, reviews: 37),
            spot("Home Spot, Malviya Nagar", 28.5355, 77.2100, .privateDriveway, 45, covered: false, ev: false, occupied: true, rating: 4.2, reviews: 12),
            spot("Society Parking, Punjabi Bagh", 28.6683, 77.1310, .privateDriveway, 40, covered: false, ev: false, occupied: false, rating: 4.3, reviews: 19)
        ]
    }

    // MARK: Private listings

    private static func makePrivateListings() -> [PrivateParkingListing] {
        [
            listing("Spacious Driveway, Greater Kailash", "M-Block Market, GK-1, New Delhi", 28.5494, 77.2426,
                    owner: hostID, ownerName: "Meera Kapoor", slots: 3, hourly: 50, daily: 350, monthly: 4500,
                    covered: false, ev: false, cctv: true, guard: false, auto: false, rating: 4.8, reviews: 64, occupied: [1]),
            listing("Covered Garage, Saket", "Press Enclave Marg, Saket, New Delhi", 28.5245, 77.2066,
                    owner: hostID, ownerName: "Meera Kapoor", slots: 2, hourly: 70, daily: 500, monthly: 6000,
                    covered: true, ev: true, cctv: true, guard: true, auto: true, rating: 4.9, reviews: 112, occupied: []),
            listing("Gated Society Spot, Vasant Vihar", "Basant Lok, Vasant Vihar, New Delhi", 28.5576, 77.1594,
                    owner: hostID, ownerName: "Meera Kapoor", slots: 4, hourly: 60, daily: 420, monthly: 5200,
                    covered: false, ev: false, cctv: true, guard: true, auto: false, rating: 4.6, reviews: 38, occupied: [2, 3]),
            listing("Terrace Parking, Lajpat Nagar", "Central Market, Lajpat Nagar II, New Delhi", 28.5677, 77.2433,
                    owner: hostID, ownerName: "Meera Kapoor", slots: 2, hourly: 45, daily: 330, monthly: 4200,
                    covered: false, ev: false, cctv: true, guard: false, auto: true, rating: 4.5, reviews: 29, occupied: [1]),
            listing("EV Bay, Greater Kailash II", "Savitri Cinema Road, GK-2, New Delhi", 28.5355, 77.2430,
                    owner: hostID, ownerName: "Meera Kapoor", slots: 3, hourly: 85, daily: 600, monthly: 7500,
                    covered: true, ev: true, cctv: true, guard: true, auto: false, rating: 4.9, reviews: 73, occupied: [3]),
            listing("Courtyard Spot, Nehru Place", "Nehru Place Metro Road, New Delhi", 28.5494, 77.2518,
                    owner: hostID, ownerName: "Meera Kapoor", slots: 5, hourly: 55, daily: 380, monthly: 4800,
                    covered: false, ev: false, cctv: true, guard: true, auto: true, rating: 4.4, reviews: 41, occupied: [1, 2]),
            listing("Home Parking, Hauz Khas Village", "Deer Park Road, Hauz Khas, New Delhi", 28.5535, 77.1941,
                    owner: otherHostID, ownerName: "Rohit Verma", slots: 2, hourly: 45, daily: 320, monthly: 4000,
                    covered: false, ev: false, cctv: false, guard: false, auto: true, rating: 4.4, reviews: 21, occupied: []),
            listing("EV Charging Bay, Connaught Place", "Barakhamba Road, Connaught Place, New Delhi", 28.6304, 77.2177,
                    owner: otherHostID, ownerName: "Rohit Verma", slots: 3, hourly: 90, daily: 650, monthly: 8000,
                    covered: true, ev: true, cctv: true, guard: true, auto: true, rating: 4.7, reviews: 87, occupied: [1]),
            listing("Basement Bay, Gurugram Sector 29", "Leisure Valley Road, Sector 29, Gurugram", 28.4595, 77.0680,
                    owner: otherHostID, ownerName: "Rohit Verma", slots: 4, hourly: 65, daily: 450, monthly: 5500,
                    covered: true, ev: true, cctv: true, guard: true, auto: true, rating: 4.6, reviews: 52, occupied: [2]),
            listing("Side Lot, Noida Sector 18", "Atta Market, Sector 18, Noida", 28.5700, 77.3260,
                    owner: otherHostID, ownerName: "Rohit Verma", slots: 3, hourly: 40, daily: 290, monthly: 3600,
                    covered: false, ev: false, cctv: false, guard: false, auto: true, rating: 4.2, reviews: 18, occupied: []),
            listing("Quiet Lane Spot, Defence Colony", "Defence Colony Market, New Delhi", 28.5738, 77.2307,
                    owner: otherHostID, ownerName: "Rohit Verma", slots: 1, hourly: 40, daily: 280, monthly: 3500,
                    covered: false, ev: false, cctv: true, guard: false, auto: false, rating: 4.3, reviews: 15, occupied: [])
        ]
    }

    private static func listing(
        _ title: String, _ address: String, _ lat: Double, _ lng: Double,
        owner: UUID, ownerName: String, slots: Int, hourly: Double, daily: Double, monthly: Double,
        covered: Bool, ev: Bool, cctv: Bool, guard securityGuard: Bool, auto: Bool,
        rating: Double, reviews: Int, occupied: Set<Int>
    ) -> PrivateParkingListing {
        let labels = ["Garage", "Driveway Left", "Driveway Right", "Front Yard"]
        let slotList = (1...slots).map { i in
            PrivateParkingSlot(
                id: UUID(),
                slotNumber: i,
                slotLabel: slots > 1 ? labels[min(i - 1, labels.count - 1)] : nil,
                vehicleSize: i == 1 ? .large : .standard,
                canFitSUV: i <= 2,
                canFitBike: true,
                isOccupied: occupied.contains(i),
                isDisabled: false,
                currentBookingID: occupied.contains(i) ? UUID() : nil,
                bookingEndTime: occupied.contains(i) ? Date().addingTimeInterval(Double(i) * 5400) : nil
            )
        }
        return PrivateParkingListing(
            id: UUID(), ownerID: owner, ownerName: ownerName, title: title, address: address,
            coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            listingDescription: "Safe, easy-access parking in a residential area. Clearly marked bays and round-the-clock entry.",
            slots: slotList, hourlyRate: hourly, dailyRate: daily, monthlyRate: monthly,
            flatFullBookingRate: hourly * Double(slots) * 8,
            autoAcceptBookings: auto, instantBookingDiscount: auto ? 10 : nil,
            hasCCTV: cctv, isCovered: covered, hasEVCharging: ev, hasSecurityGuard: securityGuard,
            hasWaterAccess: true, is24Hours: true, availableFrom: nil, availableTo: nil,
            availableDays: [1, 2, 3, 4, 5, 6, 7], rating: rating, reviewCount: reviews, imageURLs: [],
            maxBookingDuration: .unlimited, suggestedHourlyRate: nil
        )
    }

    // MARK: Commercial facilities

    private static func makeFacilities() -> [CommercialParkingFacility] {
        [
            facility("Select Citywalk Parking", "Saket District Centre, New Delhi", 28.5285, 77.2182, .mall,
                     floors: [0, -1, -2], perFloor: 8, rate: 60, flat: 400, ev: true, valet: true, wash: true, rating: 4.7, reviews: 342),
            facility("DLF Promenade Parking", "Nelson Mandela Marg, Vasant Kunj, New Delhi", 28.5398, 77.1546, .mall,
                     floors: [0, -1], perFloor: 10, rate: 80, flat: 550, ev: true, valet: true, wash: false, rating: 4.8, reviews: 521),
            facility("Cyber Hub Multilevel Parking", "DLF Cyber City, Gurugram", 28.4950, 77.0890, .office,
                     floors: [0, 1, 2], perFloor: 8, rate: 50, flat: 350, ev: true, valet: false, wash: false, rating: 4.5, reviews: 198),
            facility("IGI Airport T3 Parking", "Terminal 3, IGI Airport, New Delhi", 28.5562, 77.0999, .airport,
                     floors: [0, 1], perFloor: 10, rate: 120, flat: 900, ev: false, valet: true, wash: false, rating: 4.6, reviews: 640),
            facility("AIIMS Visitor Parking", "Ansari Nagar, New Delhi", 28.5672, 77.2100, .hospital,
                     floors: [0], perFloor: 12, rate: 30, flat: 200, ev: false, valet: false, wash: false, rating: 4.1, reviews: 89)
        ]
    }

    private static func facility(
        _ name: String, _ address: String, _ lat: Double, _ lng: Double, _ type: CommercialFacilityType,
        floors: [Int], perFloor: Int, rate: Double, flat: Double,
        ev: Bool, valet: Bool, wash: Bool, rating: Double, reviews: Int
    ) -> CommercialParkingFacility {
        var slots: [CommercialParkingSlot] = []
        for floor in floors {
            let prefix = floor == 0 ? "G" : (floor < 0 ? "B\(abs(floor))" : "L\(floor)")
            for n in 1...perFloor {
                let occupied = (n * 7 + abs(floor) * 3) % 5 < 2
                let slotType: CommercialSlotType = ev && n <= 2 ? .evCharging : (n == perFloor ? .accessible : .regular)
                slots.append(CommercialParkingSlot(
                    id: UUID(),
                    slotNumber: "\(prefix)-\(String(format: "%02d", n))",
                    slotType: slotType,
                    floor: floor,
                    isOccupied: occupied,
                    isDisabled: false,
                    currentBookingID: occupied ? UUID() : nil,
                    bookingEndTime: occupied ? Date().addingTimeInterval(Double(n) * 2700) : nil,
                    hourlyRateOverride: slotType == .evCharging ? rate + 20 : nil
                ))
            }
        }
        return CommercialParkingFacility(
            id: UUID(), name: name, address: address,
            coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            facilityType: type, slots: slots, defaultHourlyRate: rate, flatDayRate: flat,
            hasCCTV: true, hasEVCharging: ev, hasValetService: valet, hasCarWash: wash, is24Hours: true,
            rating: rating, reviewCount: reviews, ownerID: otherHostID, ownerName: "Prime Parking Co."
        )
    }

    // MARK: Bookings

    /// Host-side requests: two awaiting approval, one in progress, one finished.
    private static func makePrivateBookingRequests() -> [PrivateBooking] {
        guard let mine = privateListings.first(where: { $0.ownerID == hostID }),
              let slot = mine.slots.first else { return [] }
        let now = Date()

        func request(_ name: String, _ vehicle: String, start: TimeInterval, hours: Double,
                     status: PrivateBookingStatus, requested: TimeInterval) -> PrivateBooking {
            let rate = mine.hourlyRate
            return PrivateBooking(
                id: UUID(), listingID: mine.id, slotID: slot.id, driverID: UUID(), hostID: hostID,
                driverName: name, driverPhone: "+91 99000 1\(Int.random(in: 1000...9999))", vehicleNumber: vehicle,
                requestTime: now.addingTimeInterval(requested),
                scheduledStartTime: now.addingTimeInterval(start),
                scheduledEndTime: now.addingTimeInterval(start + hours * 3600),
                actualStartTime: status == .active ? now.addingTimeInterval(start) : nil,
                actualEndTime: status == .completed ? now.addingTimeInterval(start + hours * 3600) : nil,
                durationType: .hourly, agreedRate: rate, estimatedCost: rate * hours,
                actualCost: status == .completed ? rate * hours : nil,
                hostEarnings: status == .completed ? rate * hours * 0.85 : nil,
                status: status, approvalTime: nil, rejectionReason: nil,
                accessPIN: status == .active || status == .completed ? String(format: "%06d", Int.random(in: 100000...999999)) : nil,
                driverMessage: nil, hostMessage: nil
            )
        }

        return [
            request("Rahul Mehta", "DL 3C AB 1234", start: 3600, hours: 3, status: .pendingApproval, requested: -600),
            request("Priya Nair", "HR 26 DK 5678", start: 7200, hours: 5, status: .pendingApproval, requested: -1500),
            request("Karan Singh", "DL 8S CX 4321", start: -5400, hours: 4, status: .active, requested: -90000),
            request("Vikram Joshi", "DL 1C MN 7788", start: 10800, hours: 2, status: .pendingApproval, requested: -300),
            request("Ananya Rao", "KA 05 MH 2210", start: -1800, hours: 3, status: .active, requested: -50000),
            request("Sneha Iyer", "UP 16 BT 9087", start: -172800, hours: 6, status: .completed, requested: -180000),
            request("Manish Gupta", "DL 9C PQ 5543", start: -259200, hours: 4, status: .completed, requested: -270000),
            request("Divya Menon", "HR 51 AX 3321", start: -345600, hours: 8, status: .completed, requested: -350000),
            request("Arjun Bedi", "DL 2C RT 6409", start: -432000, hours: 2, status: .completed, requested: -440000)
        ]
    }

    private static func makeCommercialBookings() -> [CommercialBooking] {
        guard let first = commercialFacilities.first, let second = commercialFacilities.dropFirst().first,
              let slotA = first.slots.first(where: { !$0.isOccupied }),
              let slotB = second.slots.first(where: { !$0.isOccupied }) else { return [] }
        let now = Date()

        func booking(_ facility: CommercialParkingFacility, _ slot: CommercialParkingSlot,
                     start: TimeInterval, hours: Double, status: CommercialBookingStatus) -> CommercialBooking {
            CommercialBooking(
                id: UUID(), facilityID: facility.id, slotID: slot.id, driverID: driverID,
                bookingTime: now.addingTimeInterval(start - 3600),
                scheduledStartTime: now.addingTimeInterval(start),
                scheduledEndTime: now.addingTimeInterval(start + hours * 3600),
                actualStartTime: status == .completed ? now.addingTimeInterval(start) : nil,
                actualEndTime: status == .completed ? now.addingTimeInterval(start + hours * 3600) : nil,
                hourlyRate: facility.defaultHourlyRate, estimatedDuration: hours,
                estimatedCost: facility.defaultHourlyRate * hours * 1.18,
                actualCost: status == .completed ? facility.defaultHourlyRate * hours * 1.18 : nil,
                vehicleNumber: "DL 4C AA 2026", vehicleType: "Sedan", status: status,
                accessCode: String(format: "%06d", Int.random(in: 100000...999999))
            )
        }

        return [
            booking(first, slotA, start: -259200, hours: 3, status: .completed),
            booking(second, slotB, start: 86400, hours: 2, status: .pending)
        ]
    }

    /// Seven days of finished sessions (earnings charts) plus one live session.
    private static func makeBookingSessions() -> [BookingSession] {
        let now = Date()
        let calendar = Calendar.current
        let spotID = privateListings.first(where: { $0.ownerID == hostID })?.id ?? UUID()

        var sessions: [BookingSession] = (0..<7).map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? day
            let hours = Double(2 + (daysAgo * 3) % 5)
            let cost = 50 * hours
            return BookingSession(
                id: UUID(), spotID: spotID, userID: hostID,
                bookingTime: start.addingTimeInterval(-3600),
                scheduledStartTime: start, actualStartTime: start,
                scheduledEndTime: start.addingTimeInterval(hours * 3600),
                actualEndTime: start.addingTimeInterval(hours * 3600),
                duration: hours, totalCost: cost, overstayFee: nil,
                status: .completed, accessCode: nil
            )
        }
        sessions.append(BookingSession(
            id: UUID(), spotID: spotID, userID: hostID,
            bookingTime: now.addingTimeInterval(-7200),
            scheduledStartTime: now.addingTimeInterval(-5400), actualStartTime: now.addingTimeInterval(-5400),
            scheduledEndTime: now.addingTimeInterval(7200), actualEndTime: nil,
            duration: 3, totalCost: 150, overstayFee: nil, status: .active, accessCode: "482915"
        ))
        return sessions
    }
}
