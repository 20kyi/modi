import { ConceptCategory } from '../../src/generated/prisma/client';

/**
 * iOS PhotoCollection.builtIn 과 동일한 UUID·필드.
 * @see MODI/Models/PhotoCollection.swift
 */
export type SystemConceptSeed = {
  id: string;
  title: string;
  emoji: string;
  category: ConceptCategory;
  description: string;
  missionPrompt: string;
  themeColorHex: string;
};

export const systemConcepts: SystemConceptSeed[] = [
  // Color
  {
    id: 'a1000001-0000-0000-0000-000000000001',
    title: 'Pink Love',
    emoji: '🩷',
    category: ConceptCategory.COLOR,
    description: '사랑스러운 분홍빛 순간을 모아요',
    missionPrompt: '분홍색을 찍으세요',
    themeColorHex: 'F8DDE8',
  },
  {
    id: 'a1000001-0000-0000-0000-000000000002',
    title: 'Blue Mood',
    emoji: '💙',
    category: ConceptCategory.COLOR,
    description: '차분한 파란 순간들을 모아보세요',
    missionPrompt: '파란색을 찍으세요',
    themeColorHex: 'D4E4F7',
  },
  {
    id: 'a1000001-0000-0000-0000-000000000003',
    title: 'Purple Dream',
    emoji: '💜',
    category: ConceptCategory.COLOR,
    description: '몽환적인 보라빛 하루를 기록해요',
    missionPrompt: '보라색을 찍으세요',
    themeColorHex: 'E8DDF5',
  },
  {
    id: 'a1000001-0000-0000-0000-000000000004',
    title: 'Yellow Day',
    emoji: '💛',
    category: ConceptCategory.COLOR,
    description: '밝고 따뜻한 노란 하루를 담아요',
    missionPrompt: '노란색을 찍으세요',
    themeColorHex: 'F9F0C8',
  },
  {
    id: 'a1000001-0000-0000-0000-000000000005',
    title: 'Green Life',
    emoji: '💚',
    category: ConceptCategory.COLOR,
    description: '싱그러운 초록의 일상을 수집해요',
    missionPrompt: '초록색을 찍으세요',
    themeColorHex: 'D8EDDF',
  },
  {
    id: 'a1000001-0000-0000-0000-000000000006',
    title: 'White Moment',
    emoji: '🤍',
    category: ConceptCategory.COLOR,
    description: '고요하고 깨끗한 순간을 남겨요',
    missionPrompt: '하얀색을 찍으세요',
    themeColorHex: 'F2F2F4',
  },

  // Nature
  {
    id: 'b2000001-0000-0000-0000-000000000001',
    title: 'Cloud Hunter',
    emoji: '☁️',
    category: ConceptCategory.NATURE,
    description: '하늘 위 구름을 찾아 떠나요',
    missionPrompt: '하늘을 찍으세요',
    themeColorHex: 'E4ECF4',
  },
  {
    id: 'b2000001-0000-0000-0000-000000000002',
    title: 'Little Plant',
    emoji: '🪴',
    category: ConceptCategory.NATURE,
    description: '작은 식물과 함께한 순간들',
    missionPrompt: '식물을 찍으세요',
    themeColorHex: 'DCE8D4',
  },
  {
    id: 'b2000001-0000-0000-0000-000000000003',
    title: 'Flower Diary',
    emoji: '🌸',
    category: ConceptCategory.NATURE,
    description: '피어난 꽃의 아름다움을 기록해요',
    missionPrompt: '꽃을 찍으세요',
    themeColorHex: 'F5E0E8',
  },
  {
    id: 'b2000001-0000-0000-0000-000000000004',
    title: 'Animal Friend',
    emoji: '🐾',
    category: ConceptCategory.NATURE,
    description: '귀여운 동물 친구들을 만나요',
    missionPrompt: '동물을 찍으세요',
    themeColorHex: 'EDE4D8',
  },
  {
    id: 'b2000001-0000-0000-0000-000000000005',
    title: 'Sky Time',
    emoji: '🌙',
    category: ConceptCategory.NATURE,
    description: '밤하늘과 저녁 노을의 시간',
    missionPrompt: '밤하늘을 찍으세요',
    themeColorHex: 'D8DCE8',
  },
];
