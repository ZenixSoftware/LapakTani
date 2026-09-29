import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://ruccdxtmsvdgiorurvoo.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1Y2NkeHRtc3ZkZ2lvcnVydm9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1NTIzMTcsImV4cCI6MjEwNjEyODMxN30.y0rbkIHTIQvPyLdSSLBwxjpraAp5JbpMci-dMg81bMA';

  static SupabaseClient get client => Supabase.instance.client;
}
