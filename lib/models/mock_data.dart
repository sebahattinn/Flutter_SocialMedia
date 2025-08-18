import 'post.dart';
import 'user.dart';

// pravatar CORS sorunları yüzünden picsum kullanalım
String _avatar(int i) => 'https://picsum.photos/seed/user$i/200/200';

final users = List.generate(5, (i) {
  return AppUser(
    id: 'u$i',
    handle: 'user$i',
    name: 'User $i',
    avatarUrl: _avatar(i),
    bio: 'Dreamer • Builder • Coffee',
  );
});

final posts = [
  Post(
    id: 'p1',
    author: users[0],
    text: 'First light + fresh code ☕️',
    imageUrls: const [
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1200&auto=format&fit=crop',
    ],
    createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    likes: 93,
    comments: 14,
    shares: 2,
  ),
  Post(
    id: 'p2',
    author: users[1],
    text: "Designing the week. What's your plan?",
    // sadece metin
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    likes: 41,
    comments: 6,
    shares: 1,
  ),
  Post(
    id: 'p3',
    author: users[2],
    text: 'Sunset run hits different.',
    imageUrls: const [
      'https://images.unsplash.com/photo-1501973801540-537f08ccae7b?q=80&w=1200&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1200&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1200&auto=format&fit=crop', // örnek tekrar
    ],
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    likes: 320,
    comments: 22,
    shares: 9,
  ),
  // İstersen video örneği:
  Post(
    id: 'p4',
    author: users[3],
    text: 'Tiny demo clip (≤10s).',
    videoUrl: 'https://filesamples.com/samples/video/mp4/sample_640x360.mp4',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    likes: 12,
    comments: 2,
    shares: 0,
  ),
];
