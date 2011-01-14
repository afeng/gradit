package edu.berkeley.cs
package scads
package piql
package gradit

import storage._
import avro.marker._

import org.apache.avro.util._

case class Word(var wordid: Int) extends AvroPair {
  //assign PK int to do randomness, but need to provide int when loading in words
  var word: String = _
  var definition: String = _
}

case class WordListWord(var wordlist: String, var word: Int) extends AvroPair {
    var v = 1
}

case class WordList(var name: String) extends AvroPair {
    var v = 1
}

case class Book(var title: String) extends AvroPair {
    var v = 1
}


//call WORDcontext
case class WordContext(var word: Int, var book: String, var linenum: Int) extends AvroPair {
    // PKEY: var book: String = _ (book name)
    // PKEY: var linenum: Integer = _
    // PKEY: var word: Int = _ (word ID)
    var wordLine: String = _
}
/*
case class Context(var contextId: Int) extends AvroPair {
var word: Word = _
var book: Book = _
var wordLine: String = _
var before: String = _
var after: String = _
}
*/

class GraditClient(val cluster: ScadsCluster, executor: QueryExecutor) {
  implicit val exec = executor
  val maxResultsPerPage = 10

  // namespaces are declared to be lazy so as to allow for manual
  // createNamespace calls to happen first (and after instantiating this
  // class)

  lazy val words = cluster.getNamespace[Word]("words").asInstanceOf[Namespace]
  lazy val books = cluster.getNamespace[Book]("books").asInstanceOf[Namespace]
  lazy val wordcontexts = cluster.getNamespace[WordContext]("wordcontexts").asInstanceOf[Namespace]
  lazy val wordlists = cluster.getNamespace[WordList]("wordlists").asInstanceOf[Namespace]
  lazy val wordlistword = cluster.getNamespace[WordListWord]("wordlistword").asInstanceOf[Namespace]


  // findWord
  // Primary key lookup for word
  
    val findWord = (
        words
            .where("word.wordid".a === (0.?))
            .limit(1)
    ).toPiql
  
  //contextsForWord
  // Finds all contexts for a particular word given
  
    val contextsForWord = (
        wordcontexts
            .where("wordcontexts.word".a === (0.?))
            .limit(50)
    ).toPiql
  
  //wordsFromWordlist
    val wordsFromWordList = (
        wordlistword
            .where("wordlistword.wordlist".a === (0.?))
            .limit(50)
            .join(words)
            .where("words.wordid".a === "wordlistword.word".a)
    ).toPiql
}
