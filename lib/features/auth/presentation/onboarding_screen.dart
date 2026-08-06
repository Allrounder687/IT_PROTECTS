import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';

final hasPinProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final pinHash = await repo.getPinHash();
  return pinHash != null;
});

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPinAsync = ref.watch(hasPinProvider);

    return hasPinAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (hasPin) {
        if (hasPin) {
          // If they already have a PIN, redirect them to the unlock screen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/setup-pin');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome to IT PROTECTS',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your ultimate client-side encrypted vault. No one else has the keys, not even us.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.go('/setup-pin/create'),
                        child: const Text('Set Up IT PROTECTS'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Restore existing vault'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

