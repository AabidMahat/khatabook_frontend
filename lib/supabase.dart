import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

class SupabaseStorage extends StatefulWidget {
  const SupabaseStorage({super.key});

  @override
  State<SupabaseStorage> createState() => _SupabaseStorageState();
}

class _SupabaseStorageState extends State<SupabaseStorage> {

  final supabaseClient = SupabaseClient(
    'https://qlbruwvurmckjguvvjmp.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYnJ1d3Z1cm1ja2pndXZ2am1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc0Nzg5ODMsImV4cCI6MjAzMzA1NDk4M30.AJFS6eia23B5bAZsuSCB8KUsbr6uTVVrVsJARVCN-to',
  );

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
