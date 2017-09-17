require_relative 'summoner'
require_relative 'match'

require 'http'

module Utils
  def self.create_request(request, params = [])
    params << "api_key=#{KEY}"
    URI("https://na1.api.riotgames.com/#{request}?#{params * '&'}")
  end

  def self.get(uri)
    print '.'
    result = HTTP.get(uri)
    return JSON.parse(result.to_s) if result.status.success?
    case result.status.code
    when 429
      time = result.headers['Retry-After'].to_i
      puts "Waiting #{time}s for request rate to reset"
      sleep(time)
      return get(uri)
    when 403
      puts 'Forbidden; Did your application key expire?'
    else
      puts "#{result.status.code}"
    end
  end

  def self.get_tier_level(tier)
    %w[
      BRONZE
      SILVER
      GOLD
      PLATINUM
      DIAMOND
      MASTER
      CHALLENGER
    ].index(tier.upcase)
  end

  def self.get_rank_level(rank)
    %w[
      I
      II
      III
      IV
      V
    ].index(rank.upcase) + 1
  end

  def self.get_summoner(summoner_id, account_id = nil)
    league_rank = get(create_request("lol/league/v3/positions/by-summoner/#{summoner_id}"))
                  .select { |x| x['queueType'] == 'RANKED_SOLO_5x5' }
                  .first
    return nil unless league_rank
    Summoner.new(
      summoner_id: summoner_id,
      account_id: account_id,
      name: league_rank['playerOrTeamName'],
      tier: league_rank['tier'],
      division: league_rank['rank'],
      lp: league_rank['leaguePoints']
    )
  end

  def self.get_ranked_match(summoner)
    matchlist = []
    get(create_request("lol/match/v3/matchlists/by-account/#{summoner.account_id}", ['queue=420']))['matches']
      .each do |m|
        match = get(create_request("lol/match/v3/matches/#{m['gameId']}"))
        matchlist << Match.new(
          game_id: match['gameId'],
          game_version: match['gameVersion'],
          summoners: match['participantIdentities']
        )
      end
    matchlist
  end

  def self.rank_summoners(matchlist)
    matchlist.map(&:summoners)
             .flatten
             .sort
  end
end
