import 'post.dart';
import 'user.dart';

const _avatars = [
  'https://i.pravatar.cc/150?img=1',
  'https://i.pravatar.cc/150?img=5',
  'https://i.pravatar.cc/150?img=11',
  'https://i.pravatar.cc/150?img=15',
  'https://i.pravatar.cc/150?img=20',
];

final users = List.generate(5, (i) {
  return AppUser(
    id: 'u$i',
    handle: 'user$i',
    name: 'User $i',
    avatarUrl: _avatars[i % _avatars.length],
    bio: 'Dreamer • Builder • Coffee',
  );
});

final posts = [
  Post(
    id: 'p1',
    author: users[0],
    text: 'First light + fresh code ☕️',
    imageUrl:
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1200',
    createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    likes: 93,
    comments: 14,
    shares: 2,
  ),
  Post(
    id: 'p2',
    author: users[1],
    text: 'Designing the week. What’s your plan?',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    likes: 41,
    comments: 6,
    shares: 1,
  ),
  Post(
    id: 'p3',
    author: users[2],
    text: 'Sunset run hits different.',
    imageUrl:
        'https://images.unsplash.com/photo-1501973801540-537f08ccae7b?q=80&w=1200',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    likes: 320,
    comments: 22,
    shares: 9,
  ),
];
