package ru.neoflex.app.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "t_note")
public class Note {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(columnDefinition="TEXT")
    private String head;
    @Column(columnDefinition="TEXT")
    private String body;
    private Long idUser;

    public Note() {}

    public Note(Long id, String head, String body) {
        this.id = id;
        this.head = head;
        this.body = body;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getHead() {
        return head;
    }

    public void setHead(String head) {
        this.head = head;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public Long getIdUser() {
        return idUser;
    }

    public void setIdUser(Long idUser) {
        this.idUser = idUser;
    }
}
