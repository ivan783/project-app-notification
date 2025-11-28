// lib/presentation/screens/home_screen.dart - Actualizado
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:push_app_new/presentation/blocs/notifications/notifications_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: context.select(
          (NotificationsBloc bloc) => Text('${bloc.state.status}'),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<NotificationsBloc>().requestPermission();
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sección de navegación rápida
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.inventory_2, size: 40),
                    title: const Text('Gestión de Productos'),
                    subtitle: const Text('Ver y administrar inventario'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.push('/products'),
                  ),
                ],
              ),
            ),
          ),
          // Lista de notificaciones
          Expanded(
            child: const _HomeView(),
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsBloc>().state.notifications;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (BuildContext context, int index) {
        final notification = notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(notification.body),
            leading: notification.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      notification.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    child: Icon(_getNotificationIcon(notification.data)),
                  ),
            trailing: Text(
              _formatDate(notification.sentDate),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            onTap: () {
              context.push('/push-details/${notification.messageId}');
            },
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(Map<String, dynamic>? data) {
    if (data == null) return Icons.notifications;
    
    switch (data['type']) {
      case 'product_created':
        return Icons.add_shopping_cart;
      case 'low_stock':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}