from pymongo import MongoClient
import imdb
import gridfs
import requests
from secret import key


class TMAPI():

    def __init__(self):
        self.key = key
        self.url = f'http://api.themoviedb.org/3/configuration?api_key={self.key}'
        self.img_url = 'http://api.themoviedb.org/3/movie/{imdbid}/images?api_key={KEY}'
        self.r = requests.get(self.url)
        self.conf = self.r.json()
        self.base_url = self.conf['images']['base_url']
        self.sizes = self.conf['images']['poster_sizes'][-1]

    def tmdb_id(self, movie_name):
        ia = imdb.Cinemagoer()
        search = ia.search_movie_advanced(movie_name)
        for movie in range(len(search)):
            if str(search[movie].data['kind']) == "movie":
                self.movie_id = f'tt{str(search[movie].movieID)}'
                return self.movie_id
        self.movie_id = ''
        return self.movie_id

    def __image_url(self, movie_name):
        image_url = self.img_url.format(KEY=self.key, imdbid=self.tmdb_id(movie_name))
        r = requests.get(image_url)
        image_name = r.json()['posters'][0]['file_path']
        self.url = "{0}{1}{2}".format(self.base_url, self.sizes, image_name)
        return self.url

    def write_image_to_mongo(self, mongo, movie_name):
        self.url = self.__image_url(movie_name)
        r = requests.get(self.url)
        content = r.content
        Mongo.insert_img(mongo, content, filename=self.movie_id)


class Mongo(TMAPI):
    def __init__(self, host, port):
        TMAPI.__init__(self)
        self.mdb = MongoClient(host, port)
        self.database = self.mdb['posters']
        self.coll = self.database['fs.files']
        self.fs = gridfs.GridFS(self.database)

    def insert_img(self, data, filename):
        mongo_id = self.fs.put(data, filename=filename)

    def read_data(self):
        ans = self.fs.find_one({'filename': self.movie_id})
        image = ans.read()
        return image

    def update(self):
        pass

    def delete(self):
        pass

    def image_cached(self, movie_name):
        present = self.fs.find_one({'filename': self.tmdb_id(movie_name)})
        if present is None:
            self.write_image_to_mongo(self, movie_name)
        return self.read_data()


mdb = Mongo('mongo', 27017)
# mdb.tmdb_id('lord of the rings')
# mdb.image_cached('lord of the rings')
# mdb.write_image_to_mongo(mdb, 'truman show')
