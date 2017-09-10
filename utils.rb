require_relative 'summoner'
require_relative 'match'

module Utils
  def self.create_request(request, params = [])
    params << "api_key=#{KEY}"
    URI("https://na1.api.riotgames.com/#{request}?#{params * '&'}")
  end

  def self.get(uri)
    result = JSON.parse(Net::HTTP.get(uri))
    # TODO: Rework this function
    while Hash === result && result['status']
      puts 'Request did not work.'
      puts result
      sleep(1)
      result = JSON.parse(Net::HTTP.get(uri))
    end

    result
  end

  def self.get_tier_level(tier)
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

  def self.get_rank_level(rank)
    %w(
      I
      II
      III
      IV
      V
    ).index(rank.upcase) + 1
  end

  def self.get_summoner(summoner_id, account_id = nil)
    league_rank = get(create_request("lol/league/v3/positions/by-summoner/#{summoner_id}"))
                      .select { |x| x['queueType'] == 'RANKED_SOLO_5x5' }
                      .first
    nil unless league_rank
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
    match_history = get(create_request("/lol/match/v3/matchlists/by-account/#{summoner.account_id}", ['queue=420']))["matches"]
      .each do |m|
          match = get(create_request("/lol/match/v3/matches/#{m['gameId']}"))
          matchlist << Match.new(
            game_id: match['gameId'],
            game_version: match['gameVersion'],
            summoners: match['participantIdentities']
          )
      end
  end
end
