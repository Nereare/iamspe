# frozen_string_literal: true

RSpec.describe Iamspe do
  it 'has a name' do
    expect(Iamspe::NAME).not_to be_nil
  end

  it 'has a slug' do
    expect(Iamspe::SLUG).not_to be_nil
  end

  it 'has a description' do
    expect(Iamspe::DESCRIPTION).not_to be_nil
  end

  it 'has a version' do
    expect(Iamspe::VERSION).not_to be_nil
  end

  it 'has an author' do
    expect(Iamspe::AUTHOR).not_to be_nil
  end

  it 'has an author email' do
    expect(Iamspe::AUTHOR_EMAIL).not_to be_nil
  end

  it 'has a author website' do
    expect(Iamspe::AUTHOR_URI).not_to be_nil
  end

  it 'has a license' do
    expect(Iamspe::LICENSE).not_to be_nil
  end

  it 'has a copyright year' do
    expect(Iamspe::YEAR).not_to be_nil
  end
end