import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';

/// About Literature Screen - Information about the app and content categories
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Literature'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // App Description
          const Text(
            'Literature is writing that captures human experience through imagination, thought, and meaning.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xxl),

          // Categories
          _buildCategorySection(
            icon: HeroIcons.bookOpen,
            title: '1. Poem',
            description:
                'Let emotion and imagination find their voice in verse.\n\nA quiet thought becomes a rhythm,\na feeling learns how to breathe on the page,\nand silence finally speaks.\n\nPoetry is when a feeling finds a few honest lines to live in.',
            types: [
              'Free Verse – Poetry without strict rules of rhyme or meter.',
              'Haiku – A short 3-line poem with a 5-7-5 syllable pattern.',
              'Spoken Word – Poetry written to be performed aloud, focusing on voice and emotion.',
              'Sonnet – A 14-line poem with a set structure, often about love or deep ideas.',
              'Limerick – A short, humorous poem with a strong rhythm and rhyme.',
              'Ode – A poem that praises or celebrates a person, object, or idea.',
              'Elegy – A reflective poem written for loss or remembrance.',
              'Ballad – A rhythmic poem that tells a story.',
              'Epic – A long poem about heroic journeys or grand events.',
              'Acrostic – A poem where the first letters of each line spell a word.',
              'Narrative Poetry – Poetry that tells a story.',
              'Prose Poetry – Written like prose but uses poetic language and imagery.',
              'Tanka – A Japanese poem with five lines.',
            ],
          ),

          _buildCategorySection(
            icon: HeroIcons.documentText,
            title: '2. Story',
            description:
                'Once there was you, who found a Literature app where your stories could live.\n\nYou wrote of beginnings and endings, of characters who loved, lost, and changed.\n\nIn a few lines or many pages, your imagination took shape.\n\nStories are short fictional narratives that bring characters, moments, and imagination together with a beginning, a journey, and an end.',
            types: [
              'Short Story – A brief fictional narrative focusing on a single event or idea.',
              'Flash Fiction – Very short stories, usually under 1,000 words.',
              'Micro Fiction – Extremely short stories told in a few sentences or less.',
              'Moral Story – Stories written to teach a lesson or value.',
              'Fable – Stories using animals or symbols to convey moral lessons.',
              'Fairy Tale – Magical and imaginative stories, often with fantasy elements.',
              'Myth – Traditional stories explaining beliefs, origins, or natural events.',
              'Legend – Stories based on historical or heroic figures, often exaggerated over time.',
              'Horror – Stories meant to scare, disturb, or unsettle the reader.',
              'Romance – Stories centered around love and relationships.',
              'Fantasy – Stories set in imaginary worlds with magical elements.',
              'Science Fiction – Stories based on futuristic, technological, or scientific ideas.',
              'Mystery – Stories focused on solving a puzzle or crime.',
              'Thriller – Fast-paced stories filled with suspense and tension.',
              'Slice of Life – Stories depicting everyday experiences and emotions.',
              'Adventure – Stories driven by journeys, quests, and exploration.',
              'Drama – Emotion-driven stories focusing on relationships and conflict.',
            ],
          ),

          _buildCategorySection(
            icon: HeroIcons.bookmarkSquare,
            title: '3. Book',
            description:
                'You opened a book seeking one answer and found a hundred new questions.\n\nEach chapter offered insight, experience, and guidance shaped by real life.\n\nBy the final page, you understood the world a little better than before.\n\nBooks share real knowledge, ideas, experiences, and guidance through long-form writing.',
            types: [
              'Self-Help – Books focused on personal growth and improvement.',
              'Philosophy – Books exploring deep questions about life, existence, and truth.',
              'Biography – A book about someone\'s life written by another person.',
              'Autobiography – A person\'s life story written by themselves.',
              'Memoir – Personal experiences centered around specific events or periods.',
              'Spiritual – Books about spirituality, inner growth, and meaning.',
              'Religious – Books based on religious teachings, scriptures, or beliefs.',
              'History – Books that explore past events and civilizations.',
              'Psychology – Books about the human mind and behavior.',
              'Science – Books explaining scientific ideas and discoveries.',
              'Technology – Books about innovation, computing, and modern technology.',
              'Education – Instructional and learning-focused books.',
              'Business – Books on finance, entrepreneurship, and management.',
            ],
          ),

          _buildCategorySection(
            icon: HeroIcons.faceSmile,
            title: '4. Joke',
            description:
                'I made a jokes section in my app.\n\nNow its mostly people laughing at me.\n\nStill counts.\n\nJokes are short pieces of writing meant to make people laugh—sometimes even by accident.',
            types: [
              'One-Liners – Short jokes delivered in a single sentence.',
              'Puns – Jokes based on wordplay and double meanings.',
              'Satire – Humor that criticizes ideas or society in a clever way.',
              'Dark Humor – Jokes that explore serious or taboo topics lightly.',
              'Observational Humor – Jokes drawn from everyday life.',
              'Sarcasm – Humor using irony or mock praise.',
              'Parody – Humorous imitation of people, styles, or situations.',
              'Dad Jokes – Simple, predictable jokes, often intentionally cheesy.',
              'Knock-Knock Jokes – Classic call-and-response jokes.',
            ],
          ),

          _buildCategorySection(
            icon: HeroIcons.lightBulb,
            title: '5. Reflection',
            description:
                'Today, I discovered that reflections are about looking inward and sharing thoughts that help you understand what really happened.\n\nNot to judge the moment,\nbut to sit with it,\nand learn what it left behind.\n\nReflections are personal writings that explore inner thoughts, experiences, and lessons to make sense of life as it unfolds.',
            types: [
              'Personal Experience – Writing based on real-life moments and events.',
              'Life Lessons – Reflections on lessons learned through experience.',
              'Mental Health – Thoughts and feelings about emotional well-being.',
              'Spiritual Reflection – Inner experiences and spiritual insights.',
              'Growth & Healing – Writing about change, recovery, and self-development.',
              'Gratitude – Reflections focused on thankfulness and appreciation.',
              'Daily Journaling – Everyday thoughts and emotions written regularly.',
              'Philosophical Reflection – Deep thinking about life, existence, and meaning.',
              'Self-Discovery – Exploring identity, purpose, and inner awareness.',
            ],
          ),

          _buildCategorySection(
            icon: HeroIcons.academicCap,
            title: '6. Research',
            description:
                'Imagine you notice that people feel more productive at night than during the day.\n\nInstead of guessing, you observe patterns, collect responses, read what others have already studied, and analyze the results.\n\nThe process of asking the question, gathering evidence, and reaching a reasoned conclusion — that is research.',
            types: [
              'Academic Paper – Formal research written for scholarly purposes.',
              'Research Article – Published studies presenting original findings.',
              'Case Study – An in-depth examination of a specific subject or situation.',
              'Literature Review – Analysis and summary of existing research on a topic.',
              'Essay – Structured analytical writing on a specific idea or question.',
              'White Paper – Authoritative reports explaining complex issues or solutions.',
              'Survey Research – Research based on collected responses and data.',
              'Experimental Research – Research conducted through controlled experiments.',
              'Theoretical Research – Research focused on concepts, models, and frameworks.',
              'Review Paper – A critical summary and evaluation of multiple studies.',
            ],
          ),

          _buildCategorySection(
            icon: HeroIcons.newspaper,
            title: '7. Novel',
            description:
                'He left home with nothing but a letter and a promise he wasn\'t sure he could keep.\n\nYears passed, cities changed him, and love broke him more than once.\n\nWhen he finally returned, he realized the journey had rewritten who he was.\n\nA novel is this long unfolding — where time, change, and meaning grow together.',
            types: [
              'Romance – Love-driven stories and emotional relationships.',
              'Fantasy – Imaginary worlds filled with magic and myth.',
              'Science Fiction – Futures shaped by science and technology.',
              'Mystery – Stories built around solving a puzzle or crime.',
              'Thriller – Fast-paced narratives filled with tension and suspense.',
              'Horror – Stories meant to frighten or unsettle.',
              'Historical Fiction – Fiction set in real historical periods.',
              'Adventure – Journey-based stories driven by exploration and quests.',
              'Drama – Emotion-focused stories about relationships and conflict.',
              'Young Adult (YA) – Novels written for young readers.',
              'Psychological – Stories exploring the human mind.',
              'Dystopian – Dark, imagined futures shaped by control or collapse.',
            ],
          ),

          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required HeroIcons icon,
    required String title,
    required String description,
    required List<String> types,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Row(
          children: [
            HeroIcon(
              icon,
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Description
        Text(
          description,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            fontStyle: FontStyle.italic,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Types Header
        const Text(
          'Types:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // Types List
        ...types.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),

        const SizedBox(height: AppSizes.xxl),
        const Divider(color: Colors.white12),
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }
}
