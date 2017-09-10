require 'net/http'
require 'json'
require 'irb'

require_relative 'summoner'

KEY = 'YOUR_KEY_HERE'.freeze

def create_request(request)
  URI("https://na1.api.riotgames.com/#{request}?api_key=#{KEY}")
end

def get(uri)
  Net::HTTP.get(uri)
end

def get_tier_level(tier)
  %w(
    BRONZE
    SILVER
    GOLD
    PLATINUM
    DIAMOND
    MASTER
    CHALLENGER
  ).index(tier.upcase)
end

def get_rank_level(rank)
  %w(
    I
    II
    III
    IV
    V
  ).index(rank.upcase) + 1
end

def get_summoner(summoner_id)
  league_rank = JSON.parse(get(create_request("lol/league/v3/positions/by-summoner/#{summoner_id}")))
                    .select { |x| x['queueType'] == 'RANKED_SOLO_5x5' }
                    .first

  Summoner.new(
    id: summonerId,
    name: league_rank['playerOrTeamName'],
    tier: league_rank['tier'],
    division: league_rank['rank'],
    lp: league_rank['leaguePoints']
  )
end
