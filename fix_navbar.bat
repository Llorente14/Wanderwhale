@echo off
REM Script to fix duplicate navbar in flight_recommendation.dart

echo Fixing duplicate navbar...

REM Create backup
copy "flutter_app\lib\screens\flight\flight_recommendation.dart" "flutter_app\lib\screens\flight\flight_recommendation.dart.backup"

REM Remove the problematic line using findstr (inverse matching)
findstr /V "bottomNavigationBar: _buildBottomNavBar()" "flutter_app\lib\screens\flight\flight_recommendation.dart.backup" > "flutter_app\lib\screens\flight\flight_recommendation.dart"

echo Done! Backup saved as flight_recommendation.dart.backup
pause
