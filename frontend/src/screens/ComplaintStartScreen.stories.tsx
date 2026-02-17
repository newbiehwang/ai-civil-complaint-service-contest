import type { Meta, StoryObj } from '@storybook/react';
import { ComplaintStartScreen } from './ComplaintStartScreen';

const meta = {
  title: 'Screens/ComplaintStartScreen',
  component: ComplaintStartScreen,
  parameters: {
    layout: 'fullscreen',
  },
} satisfies Meta<typeof ComplaintStartScreen>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
