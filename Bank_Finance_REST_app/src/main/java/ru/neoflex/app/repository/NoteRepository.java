package ru.neoflex.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.neoflex.app.domain.Note;

import java.util.List;

public interface NoteRepository extends JpaRepository<Note, Long> {
    List<Note> findByIdUser(Long idUser);
}
