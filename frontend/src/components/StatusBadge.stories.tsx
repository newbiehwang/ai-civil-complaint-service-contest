import type { Meta, StoryObj } from '@storybook/react';
import { StatusBadge } from './StatusBadge';

const meta = {
  title: 'Components/StatusBadge',
  component: StatusBadge,
  parameters: {
    layout: 'centered',
  },
} satisfies Meta<typeof StatusBadge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Received: Story = {
  args: {
    status: 'RECEIVED',
  },
};

export const SupplementRequired: Story = {
  args: {
    status: 'SUPPLEMENT_REQUIRED',
  },
};

export const Completed: Story = {
  args: {
    status: 'COMPLETED',
  },
};
