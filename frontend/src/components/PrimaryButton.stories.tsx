import type { Meta, StoryObj } from '@storybook/react';
import { PrimaryButton } from './PrimaryButton';

const meta = {
  title: 'Components/PrimaryButton',
  component: PrimaryButton,
  parameters: {
    layout: 'centered',
  },
} satisfies Meta<typeof PrimaryButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    label: '민원 시작',
  },
};

export const Loading: Story = {
  args: {
    label: '민원 시작',
    loading: true,
  },
};

export const Disabled: Story = {
  args: {
    label: '민원 시작',
    disabled: true,
  },
};

export const Danger: Story = {
  args: {
    label: '긴급 중단',
    danger: true,
  },
};
