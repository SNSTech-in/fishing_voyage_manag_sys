import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fishing_voyage.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Boat owners table
    await db.execute('''
      CREATE TABLE boat_owners(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_name TEXT NOT NULL,
        boat_name TEXT NOT NULL,
        address TEXT NOT NULL,
        registration_number TEXT NOT NULL UNIQUE,
        aadhar_number TEXT NOT NULL UNIQUE,
        mobile_number TEXT NOT NULL UNIQUE,
        home_port TEXT NOT NULL,
        password TEXT NOT NULL,
        profile_image TEXT,
        number_of_boats INTEGER DEFAULT 1,
        registration_date TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Voyages table
    await db.execute('''
      CREATE TABLE voyages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        boat_owner_id INTEGER,
        voyage_number TEXT,
        fishing_license TEXT,
        departure_port TEXT,
        destination_port TEXT,
        voyage_date TEXT,
        expected_return_date TEXT,
        fresh_water INTEGER DEFAULT 0,
        diesel INTEGER DEFAULT 0,
        life_jackets INTEGER DEFAULT 0,
        life_buoys INTEGER DEFAULT 0,
        communication_devices INTEGER DEFAULT 0,
        previous_catch_submitted INTEGER DEFAULT 0,
        crew_count INTEGER DEFAULT 0,
        crew_names TEXT,
        status TEXT DEFAULT 'pending',
        actual_return_date TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (boat_owner_id) REFERENCES boat_owners (id)
      )
    ''');

    // Active session table
    await db.execute('''
      CREATE TABLE active_session(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_logged_in INTEGER DEFAULT 0,
        user_id INTEGER,
        phone_number TEXT,
        user_type TEXT DEFAULT 'boat_owner',
        login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES boat_owners (id)
      )
    ''');

    // Officers table
    await db.execute('''
      CREATE TABLE officers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        officer_name TEXT NOT NULL,
        address TEXT NOT NULL,
        mobile_number TEXT NOT NULL UNIQUE,
        official_email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        assigned_port TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        role TEXT DEFAULT 'port_officer',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Custom ports table
    await db.execute('''
      CREATE TABLE custom_ports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        port_name TEXT NOT NULL UNIQUE,
        is_custom INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default session row
    await db.insert('active_session', {
      'id': 1,
      'is_logged_in': 0,
      'user_id': null,
      'phone_number': null,
      'user_type': 'boat_owner'
    });

    // Insert default Lakshadweep islands
    final defaultIslands = [
      'Agati', 'Kavarati', 'Androdh', 'Kalpeni',
      'Kadmat', 'Amini', 'Chetlat', 'Bitra'
    ];

    for (var island in defaultIslands) {
      try {
        await db.insert('custom_ports', {
          'port_name': island,
          'is_custom': 0,
        });
      } catch (e) {
        // Ignore duplicate errors
      }
    }

    print('Database created successfully with all tables');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS voyages');
      await db.execute('''
        CREATE TABLE voyages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          boat_owner_id INTEGER,
          voyage_number TEXT,
          fishing_license TEXT,
          departure_port TEXT,
          destination_port TEXT,
          voyage_date TEXT,
          expected_return_date TEXT,
          fresh_water INTEGER DEFAULT 0,
          diesel INTEGER DEFAULT 0,
          life_jackets INTEGER DEFAULT 0,
          life_buoys INTEGER DEFAULT 0,
          communication_devices INTEGER DEFAULT 0,
          previous_catch_submitted INTEGER DEFAULT 0,
          crew_count INTEGER DEFAULT 0,
          crew_names TEXT,
          status TEXT DEFAULT 'pending',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (boat_owner_id) REFERENCES boat_owners (id)
        )
      ''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE active_session(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            is_logged_in INTEGER DEFAULT 0,
            user_id INTEGER,
            phone_number TEXT,
            login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES boat_owners (id)
          )
        ''');
        await db.insert('active_session', {
          'id': 1,
          'is_logged_in': 0,
          'user_id': null,
          'phone_number': null
        });
      } catch (e) {
        print('Session table already exists: $e');
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE officers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            officer_name TEXT NOT NULL,
            address TEXT NOT NULL,
            mobile_number TEXT NOT NULL UNIQUE,
            official_email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            assigned_port TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        print('Officers table created successfully');
      } catch (e) {
        print('Officers table already exists: $e');
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE custom_ports(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            port_name TEXT NOT NULL UNIQUE,
            is_custom INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        final defaultIslands = [
          'Agati', 'Kavarati', 'Androdh', 'Kalpeni',
          'Kadmat', 'Amini', 'Chetlat', 'Bitra'
        ];

        for (var island in defaultIslands) {
          try {
            await db.insert('custom_ports', {
              'port_name': island,
              'is_custom': 0,
            });
          } catch (e) {
            // Ignore duplicate errors
          }
        }
      } catch (e) {
        print('Custom ports table already exists: $e');
      }
    }

    if (oldVersion < 6) {
      try {
        // Add status and role columns to officers table
        await db.execute('ALTER TABLE officers ADD COLUMN status TEXT DEFAULT "active"');
        await db.execute('ALTER TABLE officers ADD COLUMN role TEXT DEFAULT "port_officer"');
      } catch (e) {
        print('Error adding columns to officers table: $e');
      }
    }

    if (oldVersion < 7) {
      try {
        // Add user_type column to active_session
        await db.execute('ALTER TABLE active_session ADD COLUMN user_type TEXT DEFAULT "boat_owner"');
        await db.execute('ALTER TABLE voyages ADD COLUMN actual_return_date TEXT');
        await db.execute('ALTER TABLE boat_owners ADD COLUMN number_of_boats INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE boat_owners ADD COLUMN registration_date TEXT');
      } catch (e) {
        print('Error adding columns in version 7: $e');
      }
    }

    print('Database upgraded to version $newVersion');
  }

  // SESSION MANAGEMENT METHODS
  Future<void> saveLoginSession(int userId, String phone, {String userType = 'boat_owner'}) async {
    Database db = await database;
    await db.update(
      'active_session',
      {
        'is_logged_in': 1,
        'user_id': userId,
        'phone_number': phone,
        'user_type': userType,
        'login_time': DateTime.now().toIso8601String(),
      },
      where: 'id = 1',
    );
  }

  Future<void> clearLoginSession() async {
    Database db = await database;
    await db.update(
      'active_session',
      {
        'is_logged_in': 0,
        'user_id': null,
        'phone_number': null,
        'user_type': 'boat_owner',
        'login_time': null,
      },
      where: 'id = 1',
    );
  }

  Future<bool> isUserLoggedIn() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'active_session',
      where: 'id = 1',
    );
    return result.isNotEmpty && result.first['is_logged_in'] == 1;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'active_session',
      where: 'id = 1 AND is_logged_in = 1',
    );

    if (result.isNotEmpty && result.first['user_id'] != null) {
      int userId = result.first['user_id'];
      String userType = result.first['user_type'] ?? 'boat_owner';

      if (userType == 'boat_owner') {
        return await getBoatOwnerById(userId);
      } else if (userType == 'officer') {
        return await getOfficerById(userId);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getSessionInfo() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'active_session',
      where: 'id = 1',
    );
    return result.isNotEmpty ? result.first : null;
  }

  // BOAT OWNER METHODS
  Future<int> insertBoatOwner(Map<String, dynamic> owner) async {
    Database db = await database;
    return await db.insert('boat_owners', owner);
  }

  Future<Map<String, dynamic>?> getBoatOwnerByMobile(String mobile) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'boat_owners',
      where: 'mobile_number = ?',
      whereArgs: [mobile],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getBoatOwnerById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'boat_owners',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> checkMobileExists(String mobile) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'boat_owners',
      where: 'mobile_number = ?',
      whereArgs: [mobile],
    );
    return result.isNotEmpty;
  }

  Future<int> updateBoatOwner(int id, Map<String, dynamic> owner) async {
    Database db = await database;
    return await db.update(
      'boat_owners',
      owner,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBoatOwner(int id) async {
    Database db = await database;
    return await db.delete(
      'boat_owners',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // VOYAGES METHODS
  Future<int> insertVoyage(Map<String, dynamic> voyage) async {
    Database db = await database;
    return await db.insert('voyages', voyage);
  }

  Future<List<Map<String, dynamic>>> getVoyagesByOwnerId(int ownerId) async {
    Database db = await database;
    return await db.query(
      'voyages',
      where: 'boat_owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getVoyageById(int voyageId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'voyages',
      where: 'id = ?',
      whereArgs: [voyageId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateVoyageStatus(int voyageId, String status) async {
    Database db = await database;
    return await db.update(
      'voyages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [voyageId],
    );
  }

  Future<int> updateVoyageCompletion(int voyageId, String actualReturnDate) async {
    Database db = await database;
    return await db.update(
      'voyages',
      {
        'status': 'completed',
        'actual_return_date': actualReturnDate,
      },
      where: 'id = ?',
      whereArgs: [voyageId],
    );
  }

  Future<Map<String, int>> getVoyageCountsByOwnerId(int ownerId) async {
    Database db = await database;

    List<Map<String, dynamic>> totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM voyages WHERE boat_owner_id = ?',
      [ownerId],
    );
    int total = totalResult.first['count'] as int;

    List<Map<String, dynamic>> pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM voyages WHERE boat_owner_id = ? AND status = ?',
      [ownerId, 'pending'],
    );
    int pending = pendingResult.first['count'] as int;

    List<Map<String, dynamic>> completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM voyages WHERE boat_owner_id = ? AND status = ?',
      [ownerId, 'completed'],
    );
    int completed = completedResult.first['count'] as int;

    List<Map<String, dynamic>> approvedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM voyages WHERE boat_owner_id = ? AND status = ?',
      [ownerId, 'approved'],
    );
    int approved = approvedResult.first['count'] as int;

    return {
      'total': total,
      'pending': pending,
      'completed': completed,
      'approved': approved,
    };
  }

  Future<bool> checkVoyageNumberExists(String voyageNumber) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'voyages',
      where: 'voyage_number = ?',
      whereArgs: [voyageNumber],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getVoyagesByStatus(int ownerId, String status) async {
    Database db = await database;
    return await db.query(
      'voyages',
      where: 'boat_owner_id = ? AND status = ?',
      whereArgs: [ownerId, status],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteVoyage(int voyageId) async {
    Database db = await database;
    return await db.delete(
      'voyages',
      where: 'id = ?',
      whereArgs: [voyageId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllBoatOwners() async {
    Database db = await database;
    return await db.query('boat_owners', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllVoyages() async {
    Database db = await database;
    return await db.query('voyages', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchVoyages(String query) async {
    Database db = await database;
    return await db.query(
      'voyages',
      where: 'voyage_number LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  // OFFICERS TABLE METHODS
  Future<int> addOfficer(Map<String, dynamic> officer) async {
    Database db = await database;
    return await db.insert('officers', officer);
  }

  Future<List<Map<String, dynamic>>> getAllOfficers() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        id,
        officer_name as name,
        officer_name as officer_name,
        address,
        mobile_number as mobile,
        official_email as email,
        password,
        assigned_port,
        status,
        role,
        created_at
      FROM officers 
      ORDER BY created_at DESC
    ''');
  }

  Future<Map<String, dynamic>?> getOfficerByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'officers',
      where: 'official_email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getOfficerByMobile(String mobile) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'officers',
      where: 'mobile_number = ?',
      whereArgs: [mobile],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getOfficerById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'officers',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateOfficer(int id, Map<String, dynamic> officer) async {
    Database db = await database;
    return await db.update(
      'officers',
      officer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOfficer(int id) async {
    Database db = await database;
    try {
      return await db.delete(
        'officers',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting officer: $e');
      return 0;
    }
  }

  Future<bool> checkOfficerEmailExists(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'officers',
      where: 'official_email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<bool> checkOfficerMobileExists(String mobile) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'officers',
      where: 'mobile_number = ?',
      whereArgs: [mobile],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getOfficersByPort(String port) async {
    Database db = await database;
    return await db.query(
      'officers',
      where: 'assigned_port = ?',
      whereArgs: [port],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> getOfficerCount() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM officers',
    );
    return result.first['count'] as int;
  }

  Future<Map<String, int>> getOfficerCountByPort() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT assigned_port, COUNT(*) as count FROM officers GROUP BY assigned_port',
    );

    Map<String, int> portCounts = {};
    for (var row in result) {
      portCounts[row['assigned_port'] as String] = row['count'] as int;
    }
    return portCounts;
  }

  // CUSTOM PORTS TABLE METHODS
  Future<int> addCustomPort(Map<String, dynamic> port) async {
    Database db = await database;
    try {
      return await db.insert('custom_ports', port);
    } catch (e) {
      print('Error adding custom port: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllCustomPorts() async {
    Database db = await database;
    return await db.query('custom_ports', orderBy: 'port_name ASC');
  }

  Future<List<Map<String, dynamic>>> getOnlyCustomPorts() async {
    Database db = await database;
    try {
      return await db.query(
        'custom_ports',
        where: 'is_custom = 1',
        orderBy: 'port_name ASC',
      );
    } catch (e) {
      print('Error getting custom ports: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDefaultPorts() async {
    Database db = await database;
    return await db.query(
      'custom_ports',
      where: 'is_custom = 0',
      orderBy: 'port_name ASC',
    );
  }

  Future<List<String>> getAllPorts() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'custom_ports',
      columns: ['port_name'],
      orderBy: 'port_name ASC',
    );
    return result.map((row) => row['port_name'] as String).toList();
  }

  Future<int> deleteCustomPort(int id) async {
    Database db = await database;
    try {
      return await db.delete(
        'custom_ports',
        where: 'id = ? AND is_custom = 1',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting custom port: $e');
      return 0;
    }
  }

  Future<bool> checkPortExists(String portName) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'custom_ports',
      where: 'LOWER(port_name) = ?',
      whereArgs: [portName.toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<int> getPortCount() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM custom_ports',
    );
    return result.first['count'] as int;
  }

  Future<int> getCustomPortCount() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM custom_ports WHERE is_custom = 1',
    );
    return result.first['count'] as int;
  }

  Future<Map<String, dynamic>?> getPortByName(String portName) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'custom_ports',
      where: 'port_name = ?',
      whereArgs: [portName],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updatePort(int id, Map<String, dynamic> port) async {
    Database db = await database;
    return await db.update(
      'custom_ports',
      port,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ADMIN METHODS
  Future<void> closeDatabase() async {
    Database db = await database;
    await db.close();
  }

  Future<void> clearUserVoyages(int userId) async {
    Database db = await database;
    await db.delete(
      'voyages',
      where: 'boat_owner_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('boat_owners');
    await db.delete('voyages');
    await db.delete('officers');
    await db.delete('custom_ports', where: 'is_custom = 1');

    final defaultIslands = [
      'Agati', 'Kavarati', 'Androdh', 'Kalpeni',
      'Kadmat', 'Amini', 'Chetlat', 'Bitra'
    ];

    for (var island in defaultIslands) {
      try {
        await db.insert('custom_ports', {
          'port_name': island,
          'is_custom': 0,
        });
      } catch (e) {
        // Ignore duplicate errors
      }
    }

    await db.update(
      'active_session',
      {
        'is_logged_in': 0,
        'user_id': null,
        'phone_number': null,
        'user_type': 'boat_owner',
        'login_time': null,
      },
      where: 'id = 1',
    );
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final boatOwnersCount = await getBoatOwnerCount();
    final officersCount = await getOfficerCount();
    final voyagesCount = await getVoyageCount();
    final portsCount = await getPortCount();
    final customPortsCount = await getCustomPortCount();

    return {
      'boat_owners': boatOwnersCount,
      'officers': officersCount,
      'voyages': voyagesCount,
      'ports': portsCount,
      'custom_ports': customPortsCount,
    };
  }

  Future<int> getBoatOwnerCount() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM boat_owners',
    );
    return result.first['count'] as int;
  }

  Future<int> getVoyageCount() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM voyages',
    );
    return result.first['count'] as int;
  }

  Future<void> backupDatabase() async {
    print('Backup functionality would be implemented here');
  }
}