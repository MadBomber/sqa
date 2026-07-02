# lib/sqa/strategry/consensus.rb

require_relative 'common'

class SQA::Strategy::Consensus
  extend SQA::Strategy::Common

  def self.trade(vector)
    new(vector).my_fancy_trader
  end

  def initialize(vector)
    @vector 	= vector
    @results 	= []
  end

  def my_fancy_trader
    strat_one
    strat_two
    strat_three
    strat_four
    strat_five
    consensus
  end

  def consensus
    count = @results.tally

    buy_count = count[:buy].to_i
    sell_count = count[:sell].to_i

    if buy_count > sell_count
      :buy
    elsif sell_count > buy_count
      :sell
    else
      :hold
    end
  end

  def strat_one 	= @results << (rand(2).zero? ? :buy : :sell)
  def strat_two 	= @results << (rand(2).zero? ? :buy : :sell)
  def strat_three = @results << (rand(2).zero? ? :buy : :sell)
  def strat_four 	= @results << (rand(2).zero? ? :buy : :sell)
  def strat_five 	= @results << :hold
end
