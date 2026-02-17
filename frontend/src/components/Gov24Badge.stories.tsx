import type { Meta, StoryObj } from '@storybook/react';
import { Gov24Badge } from './Gov24Badge';

const meta = {
  title: 'Components/Gov24Badge',
  component: Gov24Badge,
  parameters: {
    layout: 'centered',
  },
} satisfies Meta<typeof Gov24Badge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
